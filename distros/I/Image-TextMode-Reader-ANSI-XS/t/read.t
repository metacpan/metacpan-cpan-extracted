use Test::More tests => 24;

use strict;
use warnings;

use_ok( 'Image::TextMode::Format::ANSI' );

my @files = qw( test1.ans test2.ans test3.ans );

for my $file ( @files ) {
    my $ansi = Image::TextMode::Format::ANSI->new;
    isa_ok( $ansi->reader, 'Image::TextMode::Reader::ANSI::XS' );
    $ansi->read( "t/data/${ file }" );

    isa_ok( $ansi, 'Image::TextMode::Format::ANSI' );
    is( $ansi->width,  4, "${ file } width()" );
    is( $ansi->height, 1, "${ file } height()" );

    isa_ok( $ansi->font, 'Image::TextMode::Font::8x16' );
    isa_ok( $ansi->palette, 'Image::TextMode::Palette::ANSI' );

    if ( $ansi->has_sauce ) {
        isa_ok( $ansi->sauce, 'Image::TextMode::SAUCE' );
        is( $ansi->title, 'Test', "${ file } sauce->title()" );
    }

    is_deeply(
        $ansi->pixeldata,
        [   [   { char => 'T', attr => 8 },
                { char => 'E', attr => 207 },
                { char => 'S', attr => 68 },
                { char => 'T', attr => 35 },
            ]
        ],
        "${ file } pixeldata"
    );
}
