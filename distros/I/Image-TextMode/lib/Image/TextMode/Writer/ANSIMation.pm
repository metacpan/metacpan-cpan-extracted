package Image::TextMode::Writer::ANSIMation;

use Moo;
use charnames ':full';

extends 'Image::TextMode::Writer';

sub _write {
    my ( $self, $anim, $fh, $options ) = @_;

    # clear screen
    print $fh "\N{ESCAPE}[2J";

    my $prevattr = '';
    for my $image ( @{ $anim->frames } ) {
        my ( $width, $height ) = $image->dimensions;

        for my $y ( 0 .. $height - 1 ) {
            my $max_x = $image->max_x( $y );

            unless ( defined $max_x ) {
                print $fh "\n";
                next;
            }

            for my $x ( 0 .. $max_x ) {
                my $pixel = $image->getpixel( $x, $y )
                    || { char => ' ', attr => 7 };
                my $attr = _gen_args( $pixel->{ attr } );
                if ( $attr ne $prevattr ) {
                    print $fh "\N{ESCAPE}[0;", _gen_args( $pixel->{ attr } ),
                        'm';
                    $prevattr = $attr;
                }
                print $fh $pixel->{ char };
            }
            print $fh "\n" unless $max_x == 79;
        }

        # set position
        if ( $image ne $anim->frames->[ -1 ] ) {
            print $fh "\N{ESCAPE}[H";
        }
    }

    # clear attrs
    print $fh "\N{ESCAPE}[0m";
}

sub _gen_args {
    my $attr = shift;
    my $fg   = 30 + ( $attr & 7 );
    my $bg   = 40 + ( ( $attr & 112 ) >> 4 );
    my $bl   = ( $attr & 128 ) ? 5 : '';
    my $in   = ( $attr & 8 ) ? 1 : '';
    return join( q{;}, grep { length } ( $bl, $in, $fg, $bg ) );
}

=head1 NAME

Image::TextMode::Writer::ANSIMation - Writes ANSIMation files

=head1 DESCRIPTION

Provides writing capabilities for the ANSIMation format.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
