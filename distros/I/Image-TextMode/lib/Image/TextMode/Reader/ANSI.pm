package Image::TextMode::Reader::ANSI;

use Moo;
use Types::Standard qw( Int HashRef Bool Object );
use charnames ':full';

extends 'Image::TextMode::Reader';

# State definitions
my $S_TXT      = 0;
my $S_CHK_B    = 1;
my $S_WAIT_LTR = 2;
my $S_END      = 3;

has 'tabstop' => ( is => 'rw', isa => Int, default => 8 );

has 'save_x' => ( is => 'rw', isa => Int, default => 0 );

has 'save_y' => ( is => 'rw', isa => Int, default => 0 );

has 'x' => ( is => 'rw', isa => Int, default => 0 );

has 'y' => ( is => 'rw', isa => Int, default => 0 );

has 'attr' => ( is => 'rw', isa => Int, default => 7 );

has 'rgbattr' => ( is => 'rw', isa => HashRef, default => sub { { fg => [ 0xaa, 0xaa, 0xaa ], bg => [ 0, 0, 0 ] } } );

has 'is_truecolor' => ( is => 'rw', isa => Bool, default => 0 );

has 'state' => ( is => 'rw', isa => Int, default => $S_TXT );

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

    # make sure we reset the state of the parser
    $self->state( $S_TXT );

    my ( $argbuf, $ch );
    while ( read( $fh, $ch, 1 ) ) {
        my $state = $self->state;
        last if tell( $fh ) > $options->{ filesize };
        if ( $state == $S_TXT ) {
            if ( $ch eq "\N{SUBSTITUTE}" ) {
                $self->state( $S_END );
            }
            elsif ( $ch eq "\N{ESCAPE}" ) {
                $self->state( $S_CHK_B );
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
            else {
                $self->store( $ch );
            }
        }
        elsif ( $state == $S_CHK_B ) {
            if ( $ch ne '[' ) {
                $self->store( chr( 27 ) );
                $self->store( $ch );
                $self->state( $S_TXT );
            }
            else {
                $self->state( $S_WAIT_LTR );
            }
        }
        elsif ( $state == $S_WAIT_LTR ) {
            if ( $ch =~ /[a-zA-Z]/s ) {
                $argbuf =~ s{\s}{}sg;    # eliminate whitespace from args
                my @args = split( /;/s, $argbuf );

                if ( $ch eq 'm' ) {
                    $self->set_attributes( @args );
                }
                elsif ( $ch eq 'H' or $ch eq 'f' ) {
                    $self->set_position( @args );
                }
                elsif ( $ch eq 'A' ) {
                    $self->move_up( @args );
                }
                elsif ( $ch eq 'B' ) {
                    $self->move_down( @args );
                }
                elsif ( $ch eq 'C' ) {
                    $self->move_right( @args );
                }
                elsif ( $ch eq 'D' ) {
                    $self->move_left( @args );
                }
                elsif ( $ch eq 'E' ) {
                    $self->move_down( @args );
                    $self->x( 0 );
                }
                elsif ( $ch eq 'F' ) {
                    $self->move_up( @args );
                    $self->x( 0 );
                }
                elsif ( $ch eq 'G' ) {
                    $self->x( ( $args[ 0 ] || 1 ) - 1 );
                }
                elsif ( $ch eq 'h' ) {
                    $self->feature_on( $args[ 0 ] );
                }
                elsif ( $ch eq 'l' ) {
                    $self->feature_off( $args[ 0 ] );
                }
                elsif ( $ch eq 's' ) {
                    $self->save_position( @args );
                }
                elsif ( $ch eq 't' ) {
                    $self->rgb( @args );
                }
                elsif ( $ch eq 'u' ) {
                    $self->restore_position( @args );
                }
                elsif ( $ch eq 'J' ) {
                    $self->clear_screen( @args );
                }
                elsif ( $ch eq 'K' ) {
                    $self->clear_line( @args );
                }

                $argbuf = '';
                $self->state( $S_TXT );
            }
            else {
                $argbuf .= $ch;
            }
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

sub set_position {
    my ( $self, $y, $x ) = @_;
    $y = ( $y || 1 ) - 1;
    $x = ( $x || 1 ) - 1;

    $y = 0 if $y < 0;
    $x = 0 if $x < 0;

    $self->x( $x );
    $self->y( $y );
}

sub set_attributes {
    my ( $self, @args ) = @_;

    my $attr = $self->attr;
    my $rgba = $self->rgbattr;
    my $pal  = $self->image->palette->colors;

    foreach ( @args ) {
        if ( $_ == 0 ) {
            $attr = 7;
            $rgba->{ fg } = $pal->[ 7 ];
            $rgba->{ bg } = $pal->[ 0 ];
        }
        elsif ( $_ == 1 ) {
            $attr |= 8;
            $rgba->{ fg } = $pal->[ ( $attr & 15 ) ];
        }
        elsif ( $_ == 2 || $_ == 22 ) {
            $attr &= 247;
            $rgba->{ fg } = $pal->[ ( $attr & 15 ) ];
        }
        elsif ( $_ == 5 ) {
            $attr |= 128;
            $rgba->{ bg } = $pal->[ ( $attr & 240 ) >> 4 ];
        }
        elsif ( $_ == 7 || $_ == 27 ) {
            my $oldfg = $attr & 15;
            my $oldbg = ( $attr & 240 ) >> 4;
            $attr = $oldbg | ( $oldfg << 4 );
            
            $rgba->{ fg } = $pal->[ ( $attr & 15 ) ];
            $rgba->{ bg } = $pal->[ ( $attr & 240 ) >> 4 ];
        }
        elsif ( $_ == 25 ) {
            $attr &= 127;
            $rgba->{ bg } = $pal->[ ( $attr & 240 ) >> 4 ];
        }
        elsif ( $_ >= 30 and $_ <= 37 ) {
            $attr &= 248;
            $attr |= ( $_ - 30 );
            $rgba->{ fg } = $pal->[ ( $attr & 15 ) ];
        }
        elsif ( $_ >= 40 and $_ <= 47 ) {
            $attr &= 143;
            $attr |= ( ( $_ - 40 ) << 4 );
            $rgba->{ bg } = $pal->[ ( $attr & 240 ) >> 4 ];
        }
    }

    $self->attr( $attr );
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
    my $x = $self->x + ( shift || 1 );

    # check $x against $self->linewrap?

    $self->x( $x );
}

sub move_left {
    my $self = shift;
    my $x = $self->x - ( shift || 1 );

    $x = 0 if $x < 0;

    $self->x( $x );
}

sub save_position {
    my $self = shift;

    $self->save_x( $self->x );
    $self->save_y( $self->y );
}

sub restore_position {
    my $self = shift;

    $self->x( $self->save_x );
    $self->y( $self->save_y );
}

sub clear_line {
    my $self = shift;
    my $arg  = shift;

    if ( !$arg ) {    # clear to end of line
        $self->image->clear_line( $self->y, [ $self->x, -1 ] );
    }
    elsif ( $arg == 1 ) {    # clear to start of line
        $self->image->clear_line( $self->y, [ 0, $self->x ] );
    }
    elsif ( $arg == 2 ) {    #clear whole line
        $self->image->clear_line( $self->y );
    }
}

sub clear_screen {
    my $self = shift;
    my $arg  = shift;

    if( !$arg ) { # clear to end of screen, including cursor
        my $next = $self->y + 1;
        $self->image->delete_line( $next ) for 1..$self->image->height - $next + 1;
        $self->image->clear_line( $self->y, [ $self->x, -1 ] );
    }
    elsif( $arg == 1 ) { # clear to start of screen, including cursor
        $self->image->clear_line( $_ ) for 0..$self->y - 1;
        $self->image->clear_line( $self->y, [ 0, $self->x ] );
    }
    elsif( $arg == 2 ) { # clear whole screen
        $self->image->clear_screen;
        $self->x( 0 );
        $self->y( 0 );
    }
}

sub rgb {
    my $self = shift;
    my $mode = shift;
    my @rgb  = @_;

    $self->image->render_options->{ truecolor } = 1;
    $self->is_truecolor( 1 );

    $self->rgbattr->{ $mode == 0 ? 'bg' : 'fg' } = [ @rgb ];
}

sub feature_on {
    my $self = shift;
    my $arg  = shift;

    if( $arg eq '?33' ) {
        $self->image->render_options->{ blink_mode } = 0;
    }
}

sub feature_off {
    my $self = shift;
    my $arg  = shift;

    if( $arg eq '?33' ) {
        $self->image->render_options->{ blink_mode } = 1;
    }
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
    my $attr = shift;

    my $pal = $self->image->palette->colors;

    my %colors = ( attr => defined $attr ? $attr : $self->attr );
    if( $self->is_truecolor ) {
        delete $colors{ attr };
        $attr = defined $attr ? $attr : $self->rgbattr;
        push @{ $pal }, $attr->{ fg };
        $colors{ fg } = scalar @{ $pal } - 1;
        push @{ $pal }, $attr->{ bg };
        $colors{ bg } = scalar @{ $pal } - 1;
    }

    if ( defined $x and defined $y ) {
        $self->image->putpixel( { char => $char, %colors }, $x, $y );
    }
    else {
        $self->image->putpixel( { char => $char, %colors },
            $self->x, $self->y );
        $self->x( $self->x + 1 );
    }

    if ( $self->x >= $self->linewrap ) {
        $self->new_line;
    }
}

=head1 NAME

Image::TextMode::Reader::ANSI - Reads ANSI files

=head1 DESCRIPTION

Provides reading capabilities for the ANSI format.

=head1 ACCESSORS

=over 4

=item * tabstop - every Nth character will be a tab stop location (default: 8)

=item * save_x - saved x position (default: 0)

=item * save_y - saved y position (default: 0)

=item * x - current x (default: 0)

=item * y - current y (default: 0)

=item * attr - current attribute info (default: 7, gray on black)

=item * state - state of the parser (default: C<$S_TXT>)

=item * image - the image we're parsing into

=item * linewrap - max width before we wrap to the next line (default: 80)

=back

=head1 METHODS

=head2 set_position( [$x, $y] )

Moves the cursor to C<$x, $y>.

=head2 set_attributes( @args )

Sets the default attribute information (fg and bg).

=head2 move_up( $y )

Moves the cursor up C<$y> lines.

=head2 move_down( $y )

Moves the cursor down C<$y> lines.

=head2 move_left( $x )

Moves the cursor left C<$x> columns.

=head2 move_right( $x )

Moves the cursor right C<$x> columns.

=head2 save_position( )

Saves the current cursor position.

=head2 restore_position( )

Restores the saved cursor position.

=head2 clear_screen( )

Clears all data on the canvas.

=head2 clear_line( $y )

Clears the line at C<$y>.

=head2 rgb( $mode, $r, $g, $b )

Set the attribute to RGB color. Also, sets image to true-color mode.

=head2 feature_on( $code )

Enables a feature.

=head2 feature_off( $code )

Disables a feature.

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

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
