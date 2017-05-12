use Test::More tests => 23;

use strict;
use warnings;

$ENV{ IMAGE_TEXTMODE_NOXS } = 1;

use_ok( 'Image::TextMode::Format::ANSIMation' );

my @files = qw( ansimation1.ans ansimation2.ans );

for my $file ( @files ) {
    my $ansi = Image::TextMode::Format::ANSIMation->new;
    $ansi->read( "t/ansimation/data/${ file }" );

    isa_ok( $ansi, 'Image::TextMode::Format::ANSIMation' );
    my ( $w, $h ) = ( $ansi->width, $ansi->height );
    is( $w, 4, "${ file } width()" );
    is( $h, 1, "${ file } height()" );
    is_deeply( [ $ansi->dimensions ], [ $w, $h ], "${ file } dimensions()" );

    isa_ok( $ansi->font,    'Image::TextMode::Font::8x16' );
    isa_ok( $ansi->palette, 'Image::TextMode::Palette::ANSI' );

    my @frames = @{ $ansi->frames };
    is( scalar @frames, 2, "${ file } frames()" );

    for my $frame ( @frames ) {
        isa_ok( $frame, 'Image::TextMode::Canvas' );
        is_deeply(
            $frame->pixeldata,
            [   [   { char => 'T', attr => 8 },
                    { char => 'E', attr => 207 },
                    { char => 'S', attr => 68 },
                    { char => 'T', attr => 35 },
                ]
            ],
            "${ file } frame->pixeldata"
        );
    }
}

