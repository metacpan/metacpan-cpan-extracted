use Test::More tests => 11;

use strict;
use warnings;

use_ok( 'Image::TextMode::Format::ANSI' );

my @files = qw( test1-rgb.ans );

for my $file ( @files ) {
    my $ansi = Image::TextMode::Format::ANSI->new;
    isa_ok( $ansi->reader, 'Image::TextMode::Reader::ANSI::XS' );
    $ansi->read( "t/data/${ file }" );

    isa_ok( $ansi, 'Image::TextMode::Format::ANSI' );
    is( $ansi->width,  4, "${ file } width()" );
    is( $ansi->height, 1, "${ file } height()" );
    is( $ansi->render_options->{ truecolor }, 1, "${ file } truecolor" );

    isa_ok( $ansi->font,    'Image::TextMode::Font::8x16' );
    isa_ok( $ansi->palette, 'Image::TextMode::Palette::ANSI' );

    is_deeply( $ansi->palette->colors->[ 16 ], [ 0xaa, 0xaa, 0xaa ], 'rgb palette data' );
    is_deeply( $ansi->palette->colors->[ 17 ], [ 0x55, 0x55, 0xff ], 'rgb palette data' );

    is_deeply(
        $ansi->pixeldata,
        [   [   { char => 'T', attr => 8 },
                { char => 'E', fg => 16, bg => 17 },
                { char => 'S', fg => 18, bg => 19 },
                { char => 'T', fg => 20, bg => 21 },
            ]
        ],
        "${ file } pixeldata"
    );
}
