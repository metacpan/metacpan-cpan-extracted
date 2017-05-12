use Test::More tests => 73;

use strict;
use warnings;

use_ok( 'Image::TextMode::Format::ANSI' );

my @tests = (
    {   file     => 'tab.ans',
        width    => 18,
        height   => 1,
        expected => [
            [   ( undef ) x 7,
                { char => 'T', attr => 8 },
                ( undef ) x 7,
                { char => 'E', attr => 207 },
                { char => 'S', attr => 68 },
                { char => 'T', attr => 35 },
            ]
        ],
    },
    {   file     => 'move.ans',
        width    => 4,
        height   => 1,
        expected => [
            [   { char => 'T', attr => 8 },
                { char => 'E', attr => 207 },
                { char => 'S', attr => 68 },
                { char => 'T', attr => 35 },
            ]
        ],
    },
    {   file     => 'saverestore.ans',
        width    => 4,
        height   => 1,
        expected => [
            [   { char => 'T', attr => 8 },
                { char => 'E', attr => 207 },
                { char => 'S', attr => 68 },
                { char => 'T', attr => 35 },
            ]
        ],
    },
    {   file     => 'clearscreen-0.ans',
        width    => 1,
        height   => 4,
        expected => [
            [   { char => 'T', attr => 8 },
            ],
            [   { char => 'E', attr => 207 },
            ],
            [   { char => 'S', attr => 68 },
            ],
            [   { char => 'T', attr => 35 },
            ]
        ],
    },
    {   file     => 'clearscreen-1.ans',
        width    => 7,
        height   => 2,
        expected => [
            [
            ],
            [   ( undef ) x 3,
                { char => 'T', attr => 8 },
                { char => 'E', attr => 207 },
                { char => 'S', attr => 68 },
                { char => 'T', attr => 35 },
            ]
        ],
    },
    {   file     => 'clearscreen-2.ans',
        width    => 4,
        height   => 1,
        expected => [
            [   { char => 'T', attr => 8 },
                { char => 'E', attr => 207 },
                { char => 'S', attr => 68 },
                { char => 'T', attr => 35 },
            ]
        ],
    },
    {   file     => 'clearline-0.ans',
        width    => 4,
        height   => 1,
        expected => [
            [
                { char => 'T', attr => 8 },
                { char => 'E', attr => 207 },
                { char => 'S', attr => 68 },
                { char => 'T', attr => 35 },
            ]
        ],
    },
    {   file     => 'clearline-1.ans',
        width    => 7,
        height   => 1,
        expected => [
            [   ( undef ) x 3,
                { char => 'T', attr => 8 },
                { char => 'E', attr => 207 },
                { char => 'S', attr => 68 },
                { char => 'T', attr => 35 },
            ]
        ],
    },
    {   file     => 'clearline-2.ans',
        width    => 12,
        height   => 1,
        expected => [
            [   ( undef ) x 8,
                { char => 'T', attr => 8 },
                { char => 'E', attr => 207 },
                { char => 'S', attr => 68 },
                { char => 'T', attr => 35 },
            ]
        ],
    },
);

for my $test ( @tests ) {
    my $ansi = Image::TextMode::Format::ANSI->new;
    isa_ok( $ansi->reader, 'Image::TextMode::Reader::ANSI::XS' );
    my $file = $test->{ file };
    $ansi->read( "t/data/${ file }" );

    isa_ok( $ansi, 'Image::TextMode::Format::ANSI' );
    is( $ansi->width,  $test->{ width },  "${ file } width()" );
    is( $ansi->height, $test->{ height }, "${ file } height()" );

    my @expect = @{ $test->{ expected } };
    my @given  = @{ $ansi->pixeldata };
    for my $y ( 0 .. @expect - 1 ) {
        for my $x ( 0 .. @{ $expect[ $y ] } - 1 ) {
            my $pixel = $expect[ $y ]->[ $x ];
            next if !defined $pixel;
            is_deeply( $given[ $y ]->[ $x ], $pixel, "${ file } px($x, $y)" );
        }
    }
}
