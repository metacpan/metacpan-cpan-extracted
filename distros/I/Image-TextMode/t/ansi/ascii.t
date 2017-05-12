use Test::More tests => 105;

use strict;
use warnings;

$ENV{ IMAGE_TEXTMODE_NOXS } = 1;

use_ok( 'Image::TextMode::Format::ANSI' );

my @tests = (
    {   file     => 'ascii.txt',
        width    => 4,
        height   => 1,
        expected => [ [ qw( t e s t ) ] ],
    },
    {   file     => 'ascii-2lines.txt',
        width    => 5,
        height   => 2,
        expected => [ [ qw( t e s t 2 ) ], [ qw( t e s t 2 ) ], ],
    },
    {   file     => 'ascii-81cols.txt',
        width    => 80,
        height   => 2,
        expected => [ [ ( qw( 1 2 3 4 5 6 7 8 9 0 ) ) x 8 ], [ 1 ], ],
    },

);

for my $test ( @tests ) {
    my $ansi = Image::TextMode::Format::ANSI->new;
    my $file = $test->{ file };
    $ansi->read( "t/ansi/data/${ file }" );

    isa_ok( $ansi, 'Image::TextMode::Format::ANSI' );
    is( $ansi->width,  $test->{ width },  "${ file } width()" );
    is( $ansi->height, $test->{ height }, "${ file } height()" );

    my @expect = @{ $test->{ expected } };
    my @given  = @{ $ansi->pixeldata };
    for my $y ( 0 .. @expect - 1 ) {
        for my $x ( 0 .. @{ $expect[ $y ] } - 1 ) {
            my $char = $expect[ $y ]->[ $x ];
            next if !defined $char;
            my $pixel = { char => $char, attr => 7 };
            is_deeply( $given[ $y ]->[ $x ], $pixel, "${ file } px($x, $y)" );
        }
    }
}
