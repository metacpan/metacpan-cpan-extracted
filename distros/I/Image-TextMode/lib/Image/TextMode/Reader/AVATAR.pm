package Image::TextMode::Reader::AVATAR;

use Moo;
use Types::Standard qw( Int Bool Object );
use charnames ':full';

extends 'Image::TextMode::Reader';

has 'tabstop' => ( is => 'rw', isa => Int, default => 8 );

has 'x' => ( is => 'rw', isa => Int, default => 0 );

has 'y' => ( is => 'rw', isa => Int, default => 0 );

has 'insert' => ( is => 'rw', isa => Bool, default => 0 );

has 'attr' => ( is => 'rw', isa => Int, default => 3 );

has 'image' => ( is => 'rw', isa => Object );

has 'linewrap' => ( is => 'rw', isa => Int, default => 80 );

sub _read {
    my ( $self, $image, $fh, $options ) = @_;

    $self->image( $image );
    if ( $options->{ width } ) {
        $self->linewrap( $options->{ width } );
    }

    if ( $image->has_sauce ) {
        $image->render_options->{ blink_mode } = ($image->sauce->flags_id & 1) ^ 1;
    }

    seek( $fh, 0, 0 );

    my $ch;
    while ( read( $fh, $ch, 1 ) ) {
        last if tell( $fh ) > $options->{ filesize };
        if ( $ch eq "\N{SUBSTITUTE}" ) {
            last;
        }
        elsif ( $ch eq "\n" ) {
            $self->new_line;
        }
        elsif ( $ch eq "\r" ) {

            # do nothing
        }
        elsif ( $ch eq "\t" ) {
            $self->tab;
        }
        elsif ( ord $ch == 12 ) {
            $self->clear_screen;
            $self->attr( 3 );
            $self->insert( 0 );
        }
        elsif ( ord $ch == 25 ) {
            my $i;
            read( $fh, $ch, 1 );
            read( $fh, $i,  1 );
            $self->store( $ch ) for 1 .. ord $i;
        }
        elsif ( ord $ch == 22 ) {
            read( $fh, $ch, 1 );
            my $c = ord $ch;
            if ( $c == 1 ) {
                my $a;
                read( $fh, $a, 1 );
                $self->attr( ord $a & 0x7f );
            }
            elsif ( $c == 2 ) {
                $self->attr( $self->attr | 0x80 );
            }
            elsif ( $c == 3 ) {
                $self->move_up;
            }
            elsif ( $c == 4 ) {
                $self->move_down;
            }
            elsif ( $c == 5 ) {
                $self->move_left;
            }
            elsif ( $c == 6 ) {
                $self->move_right;
            }
            elsif ( $c == 7 ) {
                $self->clear_line;
            }
            elsif ( $c == 8 ) {
                my ( $x, $y );
                read( $fh, $y, 1 );
                read( $fh, $x, 1 );
                $self->set_position( ord $y, ord $x );
            }

            # AVT/0+ spec starts here
            elsif ( $c == 9 ) {
                $self->insert( 1 );
            }
            elsif ( $c == 10 || $c == 11 ) {
                my ( $n, $x0, $y0, $x1, $y1 );
                read( $fh, $n,  1 );
                read( $fh, $x0, 1 );
                read( $fh, $y0, 1 );
                read( $fh, $x1, 1 );
                read( $fh, $y1, 1 );

                $self->scroll( $c == 10 ? 'up' : 'down',
                    $n, $x0, $y0, $x1, $y1 );
            }
            elsif ( $c == 12 || $c == 13 ) {
                my ( $a, $char, $rows, $cols );
                read( $fh, $a,    1 );
                read( $fh, $char, 1 ) if $c == 13;
                read( $fh, $rows, 1 );
                read( $fh, $cols, 1 );

                $self->attr( ord $a & 0x7f );
                $self->clear_box( ord $rows, ord $cols, $char );
            }
            elsif ( $c == 14 ) {
                splice( @{ $self->image->pixeldata->[ $self->y ] },
                    $self->x, 1 );
            }
            elsif ( $c == 25 ) {
                my ( $n, $buf, $i );
                read( $fh, $n,   1 );
                read( $fh, $buf, ord $n );
                read( $fh, $i,   1 );
                my @chars = split //s, $buf;

                # According to spec, this can contain AVT/0 codes and should
                # probably be written back to the stream for parsing.
                # We'll send it directly to the screen for now.
                for ( 1 .. ord $i ) {
                    $self->store( $_ ) for @chars;
                }
            }

            $self->insert( 0 ) if $c < 9;
        }
        else {
            $self->store( $ch );
        }
    }

    return $image;
}

sub set_position {
    my ( $self, $y, $x ) = @_;
    $y = ( $y || 1 ) - 1;
    $x = ( $x || 1 ) - 1;

    $y = 0 if $y < 0;
    $x = 0 if $x < 0;

    $self->x( $x );
    $self->y( $y );
}

sub move_up {
    my $self = shift;
    my $y = $self->y - ( shift || 1 );
    $y = 0 if $y < 0;

    $self->y( $y );
}

sub move_down {
    my $self = shift;
    my $y = shift || 1;

    $self->y( $self->y + $y );
}

sub move_right {
    my $self = shift;
    my $x = shift || 1;

    $self->x( $self->x + $x );
}

sub move_left {
    my $self = shift;
    my $x = $self->x - ( shift || 1 );

    $x = 0 if $x < 0;

    $self->x( $x );
}

sub scroll {    ## no critic (Subroutines::ProhibitManyArgs)
    my ( $self, $dir, $n, $x0, $y0, $x1, $y1 ) = @_;
    $x0--;
    $y0--;
    $x1--;
    $y1--;

    my $pixeldata = $self->image->pixeldata;
    my $cols      = $x1 - $x0;
    my @rows      = $y0 .. $y1;
    if ( $dir eq 'down' ) {
        @rows = reverse @rows;
    }
    else {
        $n = 0 - $n;
    }

    my $attr = $self->attr;
    my @blank = ( { char => ' ', attr => $attr } ) x $cols;

    for my $from ( @rows ) {
        my $to = $from + $n;
        next if $to < 0;
        splice( @{ $pixeldata->[ $to ] },
            $x0, $cols, @{ $pixeldata->[ $from ] }[ $x0 .. $x1 ] );
        splice( @{ $pixeldata->[ $from ] }, $x0, $cols, @blank );
    }
}

sub clear_box {
    my ( $self, $rows, $cols, $char ) = @_;

    $char = ' ' unless defined $char;
    my $sx = $self->x;
    my $sy = $self->y;

    for my $x ( map { $sx + $_ } 0 .. $cols - 1 ) {
        for my $y ( map { $sy + $_ } 0 .. $rows - 1 ) {
            $self->store( $char, $x, $y );
        }
    }

    $self->x( $sx );
    $self->y( $sy );
}

sub clear_line {
    my $self = shift;

    $self->image->clear_line( $self->y, [ $self->x, -1 ] );
}

sub clear_screen {
    my $self = shift;

    $self->image->clear_screen;
}

sub new_line {
    my $self = shift;

    $self->y( $self->y + 1 );
    $self->x( 0 );
}

sub tab {
    my $self  = shift;
    my $count = ( $self->x + 1 ) % $self->tabstop;
    if ( $count ) {
        $count = $self->tabstop - $count;
        for ( 1 .. $count ) {
            $self->store( ' ' );
        }
    }
}

sub store {
    my $self = shift;
    my $char = shift;
    my $x    = shift;
    my $y    = shift;
    my $attr = shift || $self->attr;

    if ( $self->insert ) {
        my $col = $self->x;
        my $row = $self->image->pixeldata->[ $self->y ];
        splice( @$row, $col + 1, @$row - 1 - $col, @{ $row }[ $col .. -1 ] );
    }

    if ( defined $x and defined $y ) {
        $self->image->putpixel( { char => $char, attr => $attr }, $x, $y );
    }
    else {
        $self->image->putpixel( { char => $char, attr => $attr },
            $self->x, $self->y );
        $self->x( $self->x + 1 );
    }

    if ( $self->x >= $self->linewrap ) {
        $self->new_line;
    }
}

=head1 NAME

Image::TextMode::Reader::AVATAR - Reads AVATAR files

=head1 DESCRIPTION

Provides reading capabilities for the AVATAR format.

=head1 COMPATIBILITY

The reader implements all of the AVT/0 specification as well as the majority
of the AVT/0+ specification. The main difference being that AVT/0+ character
expansion is not re-interpreted, thus expansions containing further AVT/0
codes will simply be written as characters to the canvas. 

=head1 ACCESSORS

=over 4

=item * tabstop - every Nth character will be a tab stop location (default: 8)

=item * x - current x (default: 0)

=item * y - current y (default: 0)

=item * attr - current attribute info (default: 7, gray on black)

=item * image - the image we're parsing into

=item * insert - insert mode (default: off)

=item * linewrap - max width before we wrap to the next line (default: 80)

=back

=head1 METHODS

=head2 set_position( [$y, $x] )

Moves the cursor to C<$x, $y>.

=head2 move_up( $y )

Moves the cursor up C<$y> lines.

=head2 move_down( $y )

Moves the cursor down C<$y> lines.

=head2 move_left( $x )

Moves the cursor left C<$x> columns.

=head2 move_right( $x )

Moves the cursor right C<$x> columns.

=head2 scroll( $dir, $n, $x0, $y0, $x1, $y1 )

Scrolls box bound by (C<$x0>, C<$y0>) and (C<$x1>, C<$y1>) in direction
C<$dir> (up or down), by C<$n> lines.

=head2 clear_box( $rows, $cols [, $char] )

Clears box bound from current cursor position for C<$rows> rows and C<$cols> 
columns using C<$char> as the character.

=head2 clear_screen( )

Clears all data on the canvas.

=head2 clear_line( )

Clears the remainder of the current line.

=head2 new_line( )

Simulates a C<\n> character.

=head2 tab( )

Simulates a C<\t> character.

=head2 store( $char, $x, $y [, $attr] )

Stores C<$char> at position C<$x, $y> with either the supplied attribute
or the current attribute setting.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
