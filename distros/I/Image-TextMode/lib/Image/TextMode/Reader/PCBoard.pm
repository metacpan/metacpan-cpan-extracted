package Image::TextMode::Reader::PCBoard;

use Moo;
use Types::Standard qw( Int Object HashRef );
use charnames ':full';

extends 'Image::TextMode::Reader';

# State definitions
my $S_TXT = 0;
my $S_OP  = 1;
my $S_END = 2;

has 'linewrap' => ( is => 'rw', isa => Int, default => 80 );

has 'tabstop' => ( is => 'rw', isa => Int, default => 8 );

has 'image' => ( is => 'rw', isa => Object );

has 'attr' => ( is => 'rw', isa => Int, default => 7 );

has 'x' => ( is => 'rw', isa => Int, default => 0 );

has 'y' => ( is => 'rw', isa => Int, default => 0 );

has 'state' => ( is => 'rw', isa => Int, default => $S_TXT );

has 'codes' => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { { POFF => '', WAIT => '' } }
);

sub _read {
    my ( $self, $image, $fh, $options ) = @_;

    if ( $options->{ width } ) {
        $self->linewrap( $options->{ width } );
    }

    $image->render_options->{ blink_mode } = 0;
    $self->image( $image );

    # slurp in file so we can do code replacement
    seek( $fh, 0, 0 );
    my $pcb = do { local $/ = undef; <$fh> };

    my $code_re = join( q(|), keys %{ $self->codes } );
    $pcb =~ s{\@($code_re)\@}{$self->codes->{ $1 }}gse;

    $self->state( $S_TXT );

    my @str = split( //s, $pcb );
    while ( defined( my $ch = shift @str ) ) {
        my $state = $self->state;

        last if tell( $fh ) > $options->{ filesize };

        if ( $state == $S_TXT ) {
            if ( $ch eq "\N{SUBSTITUTE}" ) {
                $self->state( $S_END );
            }
            elsif ( $ch eq "\N{COMMERCIAL AT}" ) {
                $self->state( $S_OP );
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
        elsif ( $state == $S_OP ) {
            if ( $ch eq 'X' ) {
                $self->set_attributes( hex shift @str, hex shift @str );
            }
            elsif ( join( '', $ch, @str[ 0 .. 2 ] ) eq 'CLS@' ) {
                shift @str for 1 .. 3;
                $self->clear_screen;
            }
            elsif ( join( '', $ch, @str[ 0 .. 2 ] ) eq 'POS:' ) {
                shift @str for 1 .. 3;

                my $x = shift @str;
                $x .= shift @str if $str[ 0 ] ne q(@);
                $x--;

                shift @str;

                $self->x( $x );
            }
            else {    # not a valid OP
                $self->store( q(@) );
                $self->store( $ch );
            }
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

sub set_attributes {
    my ( $self, $bg, $fg ) = @_;

    $self->attr( ( $bg << 4 ) + $fg );
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

Image::TextMode::Reader::PCBoard - Reads PCBoard files

=head1 DESCRIPTION

Provides reading capabilities for the PCBoard format.

=head1 ACCESSORS

=over 4

=item * tabstop - every Nth character will be a tab stop location (default: 8)

=item * x - current x (default: 0)

=item * y - current y (default: 0)

=item * attr - current attribute info (default: 7, gray on black)

=item * state - state of the parser (default: C<$S_TXT>)

=item * image - the image we're parsing into

=item * linewrap - max width before we wrap to the next line (default: 80)

=item * codes - hashref of key-value pairs to substitute into the image

=back

=head1 METHODS

=head2 set_attributes( $bg, $fg )

Sets the default attribute information (fg and bg).

=head2 clear_screen( )

Clears all data on the canvas.

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
