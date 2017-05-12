use Test::More tests => 9;

use strict;
use warnings;

use_ok( 'Image::TextMode::Format::IDF' );

{
    my $file = 'test1.idf';
    my $idf  = Image::TextMode::Format::IDF->new;
    $idf->read( "t/idf/data/${file}" );

    isa_ok( $idf, 'Image::TextMode::Format::IDF' );
    is( $idf->width,  80, "${ file } width()" );
    is( $idf->height, 1,  "${ file } height()" );

    my $font = $idf->font;
    isa_ok( $font, 'Image::TextMode::Font' );

    # modified 't' char
    is_deeply(
        $font->chars->[ ord( 't' ) ],
        [ 255, 255, ( 0 ) x 14 ],
        'font: modified t'
    );

    my $pal = $idf->palette;
    isa_ok( $pal, 'Image::TextMode::Palette' );

    # modified 'brown' color
    is_deeply( $pal->colors->[ 6 ], [ 255, 255, 255 ],
        'pal: modified brown' );

    is_deeply(
        $idf->pixeldata,
        [   [   { char => 't', attr => 7 },
                { char => 'e', attr => 6 },
                { char => 's', attr => 5 },
                { char => 't', attr => 4 },
                ( { char => ' ', attr => 7 } ) x 75,
                { char => "\x0", attr => 7 },
            ]
        ],
        "${ file } pixeldata"
    );

}

