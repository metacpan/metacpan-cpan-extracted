use Test::More tests => 7;

use strict;
use warnings;

use_ok( 'Image::TextMode::Format::ATASCII' );

my @files = qw( test.ata );

for my $file ( @files ) {
    my $ata = Image::TextMode::Format::ATASCII->new;
    $ata->read( "t/atascii/data/${ file }" );

    isa_ok( $ata, 'Image::TextMode::Format::ATASCII' );
    is( $ata->width,  6, "${ file } width()" );
    is( $ata->height, 1, "${ file } height()" );

    isa_ok( $ata->font,    'Image::TextMode::Font::Atari' );
    isa_ok( $ata->palette, 'Image::TextMode::Palette::Atari' );

    is_deeply(
        $ata->pixeldata,
        [   [   { char => 'T', bg => 0, fg => 1 },
                { char => 'E', bg => 0, fg => 1 },
                { char => 'S', bg => 0, fg => 1 },
                { char => 'T', bg => 0, fg => 1 },
                { char => chr(127), bg => 0, fg => 1 },
                { char => chr(255), bg => 0, fg => 1 },
            ]
        ],
        "${ file } pixeldata"
    );
}
