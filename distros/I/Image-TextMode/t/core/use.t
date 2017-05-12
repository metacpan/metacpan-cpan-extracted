use strict;
use warnings;

use Test::More tests => 9;

use_ok( 'Image::TextMode::Format' );
use_ok( 'Image::TextMode::Canvas' );

{
    my $format = Image::TextMode::Format->new;
    isa_ok( $format, 'Image::TextMode::Format' );

    # some defaults
    isa_ok( $format->font,    'Image::TextMode::Font::8x16' );
    isa_ok( $format->palette, 'Image::TextMode::Palette::VGA' );
    isa_ok( $format->sauce,   'Image::TextMode::SAUCE' );
}

{
    my $canvas = Image::TextMode::Canvas->new;
    isa_ok( $canvas, 'Image::TextMode::Canvas' );

    # some defaults
    is( $canvas->width,  0, 'default width' );
    is( $canvas->height, 0, 'default height' );
}
