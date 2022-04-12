package Image::TextMode::Writer::Tundra;

use Moo;

extends 'Image::TextMode::Writer';

sub _write {
    my ( $self, $image, $fh, $options ) = @_;

    print $fh pack( 'C',  24 );
    print $fh pack( 'A8', 'TUNDRA24' );

    my $pal = $image->palette;

    for my $y ( 0 .. $image->height - 1 ) {
        for my $x ( 0 .. 79 ) {
            my $pixel = $image->getpixel( $x, $y );

            if ( !defined $pixel ) {
                $pixel = { char => ' ', fg => 0, bg => 0 };
            }

            my $fg = _assemble_pal( $pal->colors->[ $pixel->{ fg } ] );
            my $bg = _assemble_pal( $pal->colors->[ $pixel->{ bg } ] );
            print $fh chr( 6 ), $pixel->{ char }, pack( 'N*', $fg, $bg );
        }
    }
}

sub _assemble_pal {
    my ( $color ) = shift;
    return ( $color->[ 0 ] << 16 ) | ( $color->[ 1 ] << 8 )
        | ( $color->[ 2 ] );
}

=head1 NAME

Image::TextMode::Writer::Tundra - Writes Tundra files

=head1 DESCRIPTION

Provides writing capabilities for the Tundra format. It currently does not
support any RLE compression.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
