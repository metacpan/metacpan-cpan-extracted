package Image::TextMode::Reader::ATASCII;

use Moo;
use Types::Standard qw( Int Object );
use charnames ':full';

extends 'Image::TextMode::Reader';

# State definitions
my $S_TXT = 0;
my $S_ESC = 1;
my $S_END = 2;

has 'linewrap' => ( is => 'rw', isa => Int, default => 41 );

has 'tabstop' => ( is => 'rw', isa => Int, default => 8 );

has 'image' => ( is => 'rw', isa => Object );

has 'x' => ( is => 'rw', isa => Int, default => 0 );

has 'y' => ( is => 'rw', isa => Int, default => 0 );

has 'state' => ( is => 'rw', isa => Int, default => $S_TXT );

sub _read {
    my ( $self, $image, $fh, $options ) = @_;

    if ( $options->{ width } ) {
        $self->linewrap( $options->{ width } );
    }

    $image->render_options->{ blink_mode } = 0;
    $self->image( $image );

    $self->state( $S_TXT );

    my $ch;
    while ( read( $fh, $ch, 1 ) ) {
        my $state = $self->state;

        last if tell( $fh ) > $options->{ filesize };

        if ( $state == $S_TXT ) {
            if ( ord $ch == 27 ) {
                $self->state( $S_ESC );
            }
            elsif ( ord $ch == 28 ) {
                $self->y( $self->y - 1 );
                $self->y( 0 ) if $self->y < 0;
            }
            elsif ( ord $ch == 29 ) {
                $self->y( $self->y + 1 );
            }
            elsif ( ord $ch == 30 ) {
                $self->x( $self->x - 1 );
                $self->x( 0 ) if $self->x < 0;
            }
            elsif ( ord $ch == 31 ) {
                $self->x( $self->x + 1 );
                $self->x( $self->linewrap - 1 ) if $self->x == $self->linewrap; 
            }
            elsif ( ord $ch == 125 ) {
                $self->clear_screen;
            }
            elsif ( ord $ch == 126 ) {
                $self->x( $self->x - 1 );
                $self->store( ' ' );
                $self->x( $self->x - 1 );
            }
            elsif ( ord $ch == 127 ) {
                $self->tab;
            }
            elsif ( ord $ch == 155 ) {
                $self->new_line;
            }
            elsif ( ord $ch == 156 ) {
                # delete line
            }
            elsif ( ord $ch == 157 ) {
                # insert line
            }
            elsif ( ord $ch == 158 ) {
                # clear tab stop
            }
            elsif ( ord $ch == 159 ) {
                # set tab stop
            }
            elsif ( ord $ch == 253 ) {
                # buzzer
            }
            elsif ( ord $ch == 254 ) {
                # delete char
            }
            elsif ( ord $ch == 255 ) {
                # insert char
            }
            else {
                $self->store( $ch );
            }
        }
        elsif ( $state == $S_ESC ) {
            $self->store( $ch );
            $self->state( $S_TXT );
        }
        elsif ( $state == $S_END ) {
            last;
        }
        else {
            $self->state( $S_TXT );
        }
    }

    return $image;
}

sub clear_screen {
    my $self = shift;
    $self->image->clear_screen;
    $self->x( 0 );
    $self->y( 0 );
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

    if ( defined $x and defined $y ) {
        $self->image->putpixel( { char => $char, bg => 0, fg => 1 }, $x, $y );
    }
    else {
        $self->image->putpixel( { char => $char, bg => 0, fg => 1 },
            $self->x, $self->y );
        $self->x( $self->x + 1 );
    }

    if ( $self->x >= $self->linewrap ) {
        $self->new_line;
    }
}

=head1 NAME

Image::TextMode::Reader::ATASCII - Reads ATASCII files

=head1 DESCRIPTION

Provides reading capabilities for the ATASCII format.

=head1 ACCESSORS

=over 4

=item * tabstop - every Nth character will be a tab stop location (default: 8)

=item * x - current x (default: 0)

=item * y - current y (default: 0)

=item * state - state of the parser (default: C<$S_TXT>)

=item * image - the image we're parsing into

=item * linewrap - max width before we wrap to the next line (default: 80)

=back

=head1 METHODS

=head2 clear_screen( )

Clears all data on the canvas.

=head2 new_line( )

Simulates a C<\n> character.

=head2 tab( )

Simulates a C<\t> character.

=head2 store( $char, $x, $y )

Stores C<$char> at position C<$x, $y>.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
