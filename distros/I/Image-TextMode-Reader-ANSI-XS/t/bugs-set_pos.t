use Test::More tests => 8;

use strict;
use warnings;

use_ok( 'Image::TextMode::Format::ANSI' );

my $ansi = Image::TextMode::Format::ANSI->new;
isa_ok( $ansi->reader, 'Image::TextMode::Reader::ANSI::XS' );
$ansi->read( 't/bugs/set-pos.ans' );

is( $ansi->width,  4, 'width()' );
is( $ansi->height, 1, 'height()' );

my @expect = (
    [   { char => 't', attr => 7 },
        { char => 'E', attr => 7 },
        { char => 'S', attr => 7 },
        { char => 'T', attr => 7 },
    ]
);
my @given = @{ $ansi->pixeldata };

for my $y ( 0 .. @expect - 1 ) {
    for my $x ( 0 .. @{ $expect[ $y ] } - 1 ) {
        my $pixel = $expect[ $y ]->[ $x ];
        is_deeply( $given[ $y ]->[ $x ], $pixel, "px($x, $y)" );
    }
}
