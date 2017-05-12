use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 1 }

use Hex::Record;

my $hex = Hex::Record->new();
# merge two parts
$hex->write(0,    [ map { sprintf "%2X", $_ }  0 .. 19 ]);
$hex->write(20,   [ map { sprintf "%2X", $_ } 20 .. 29 ]);

$hex->write(50,   [ map { sprintf "%2X", $_ }  0 ..  9 ]);
$hex->write(60,   [ map { sprintf "%2X", $_ } 10 .. 19 ]);

$hex->write(71,   [ map { sprintf "%2X", $_ } 0 .. 3 ]);

$hex->write(100,  [ map { sprintf "%2X", $_ }  0 .. 19 ]);
$hex->write(130,  [ map { sprintf "%2X", $_ }  0 .. 19 ]);
$hex->write(80,   [ map { sprintf "%2X", $_ }  0 .. 99 ]);

$hex->write(1010, [ map { sprintf "%2X", $_ } 10 .. 19 ]);
$hex->write(1000, [ map { sprintf "%2X", $_ }  0 ..  9 ]);

$hex->write(1990, [ map { sprintf "%2X", $_ }  0 .. 9 ]);
$hex->write(2010, [ map { sprintf "%2X", $_ } 20 .. 29 ]);
$hex->write(2000, [ map { sprintf "%2X", $_ } 10 .. 19 ]);


my $parts_expected = [
    {
        start => 0,
        bytes => [ map { sprintf "%2X", $_ }  0 .. 29 ]
    },
    {
        start => 50,
        bytes => [ map { sprintf "%2X", $_ }  0 .. 19],
    },
    {
        start => 71,
        bytes => [ map { sprintf "%2X", $_ }  0 .. 3],
    },
    {
        start => 80,
        bytes => [ map { sprintf "%2X", $_ }  0 .. 99],
    },
    {
        start => 1000,
        bytes => [ map { sprintf "%2X", $_ }  0 .. 19]
    },
    {
        start => 1990,
        bytes => [ map { sprintf "%2X", $_ }  0 .. 29]
    },
];

is_deeply(
    $hex->{parts},
    $parts_expected,
    "successfully written hex parts"
);
