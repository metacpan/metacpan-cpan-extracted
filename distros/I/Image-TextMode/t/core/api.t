use strict;
use warnings;

use Test::More tests => 14;

use_ok( 'Image::TextMode::Canvas' );

{
    my $image = Image::TextMode::Canvas->new;
    isa_ok( $image, 'Image::TextMode::Canvas' );

    my $pixel = { char => 'X', fg => 7, bg => 0 };
    $image->putpixel( $pixel, 0, 0 );

    is_deeply( $image->pixeldata, [ [ $pixel ] ], 'putpixel() ok' );
    is_deeply( $image->getpixel( 0, 0 ), $pixel, 'getpixel() ok' );

    my ( $w, $h ) = ( $image->width, $image->height );
    is( $w, 1, 'width() ok' );
    is( $h, 1, 'height() ok' );

    is_deeply( [ $image->dimensions ], [ $w, $h ], 'dimensions() ok' );

    my $pixel_obj = $image->getpixel_obj( 0, 0 );
    isa_ok( $pixel_obj, 'Image::TextMode::Pixel' );
    is( $pixel_obj->char,  'X', 'pixel->char' );
    is( $pixel_obj->fg,    7,   'pixel->fg' );
    is( $pixel_obj->bg,    0,   'pixel->bg' );
    is( $pixel_obj->blink, 0,   'pixel->blink' );

    # non-existant pixel
    ok( !defined $image->getpixel_obj( 1, 1 ), 'non-existant pixel' );

    is( $image->as_ascii, "X\n", 'as_ascii() ok' );
}

