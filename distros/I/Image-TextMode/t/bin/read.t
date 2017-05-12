use strict;
use warnings;

use Test::More tests => 8;

use_ok( 'Image::TextMode::Format::Bin' );

{
    my $file = 'test1.bin';
    my $bin  = Image::TextMode::Format::Bin->new;
    $bin->read( "t/bin/data/${file}" );

    isa_ok( $bin, 'Image::TextMode::Format::Bin' );
    is( $bin->width,  4, "${file} width()" );
    is( $bin->height, 1, "${file} height()" );

    isa_ok( $bin->font,    'Image::TextMode::Font::8x16' );
    isa_ok( $bin->palette, 'Image::TextMode::Palette::VGA' );

    ok( !$bin->has_sauce, "${file} No SAUCE" );

    is_deeply(
        $bin->pixeldata,
        [   [   { char => 'T', attr => 8 },
                { char => 'E', attr => 79 },
                { char => 'S', attr => 68 },
                { char => 'T', attr => 35 },
            ],
        ],
        "${file} pixeldata"
    );
}
