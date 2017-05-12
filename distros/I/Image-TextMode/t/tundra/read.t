use Test::More tests => 8;

use strict;
use warnings;

use_ok( 'Image::TextMode::Format::Tundra' );

{
    my $file = 'test1.tnd';
    my $tnd  = Image::TextMode::Format::Tundra->new;
    $tnd->read( "t/tundra/data/${file}" );

    isa_ok( $tnd, 'Image::TextMode::Format::Tundra' );
    is( $tnd->width,  4, "${ file } width()" );
    is( $tnd->height, 1, "${ file } height()" );

    isa_ok( $tnd->font, 'Image::TextMode::Font::8x16' );

    my $pal = $tnd->palette;
    isa_ok( $pal, 'Image::TextMode::Palette' );
    is_deeply(
        $pal->colors,
        [   [ 0,   0,   0 ],
            [ 173, 0,   173 ],
            [ 128, 128, 0 ],
            [ 173, 0,   0 ],
            [ 255, 82,  85 ],
            [ 0,   170, 0 ],
            [ 82,  85,  82 ],
            [ 173, 170, 173 ]
        ],
        'custom palette'
    );

    is_deeply(
        $tnd->pixeldata,
        [   [   { char => 'T', fg => 1, bg => 0 },
                { char => 'E', fg => 2, bg => 3 },
                { char => 'S', fg => 4, bg => 5 },
                { char => 'T', fg => 6, bg => 7 },
            ]
        ],
        "${ file } pixeldata"
    );

}

