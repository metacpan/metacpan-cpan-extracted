use Test::More tests => 9;

use strict;
use warnings;

use_ok( 'Image::TextMode::Format::ADF' );

{
    my $file = 'test1.adf';
    my $adf  = Image::TextMode::Format::ADF->new;
    $adf->read( "t/adf/data/${file}" );

    isa_ok( $adf, 'Image::TextMode::Format::ADF' );
    is( $adf->width,  80, "${ file } width()" );
    is( $adf->height, 1,  "${ file } height()" );

    my $font = $adf->font;
    isa_ok( $font, 'Image::TextMode::Font' );

    # modified 't' char
    is_deeply(
        $font->chars->[ ord( 't' ) ],
        [ 255, 0, 16, 48, 48, 252, 48, 48, 48, 48, 54, 28, 0, 0, 0, 0 ],
        'font: modified t'
    );

    my $pal = $adf->palette;
    isa_ok( $pal, 'Image::TextMode::Palette' );

    # modified 'brown' color
    is_deeply( $pal->colors->[ 6 ], [ 255, 255, 255 ],
        'pal: modified brown' );

    is_deeply(
        $adf->pixeldata,
        [   [   { char => 't', attr => 15 },
                { char => 'e', attr => 12 },
                { char => 's', attr => 4 },
                { char => 't', attr => 6 },
                ( { char => ' ', attr => 0 } ) x 76,
            ]
        ],
        "${ file } pixeldata"
    );

}

