package Image::TextMode::Writer::XBin;

use Moo;

extends 'Image::TextMode::Writer';

my $header_template = 'A4 C v v C C';

sub _write {
    my ( $self, $image, $fh, $options ) = @_;
    my ( $width, $height ) = $image->dimensions;

    my $fontsize = $image->font->height;
    my $flags
        = 11;   # has palette and font, is non-blink, everything else is false
    $flags |= 16
        if scalar @{ $image->font->chars } == 512;    # check for large font
    print $fh pack( $header_template,
        'XBIN', 26, $width, $height, $fontsize, $flags );

    for my $color ( @{ $image->palette->colors } ) {
        print $fh pack( 'C*', map { $_ >> 2 } @$color );
    }

    for my $char ( @{ $image->font->chars } ) {
        print $fh pack( 'C*', @$char );
    }

    # No compression for now
    for my $y ( 0 .. $height - 1 ) {
        for my $x ( 0 .. $width - 1 ) {
            my $pixel = $image->getpixel( $x, $y );
            print $fh pack( 'aC', $pixel->{ char }, $pixel->{ attr } );
        }
    }
}

=head1 NAME

Image::TextMode::Writer::XBin - Writes XBin files

=head1 DESCRIPTION

Provides writing capabilities for the XBin format. It currently only
supports uncompressed XBin files.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
