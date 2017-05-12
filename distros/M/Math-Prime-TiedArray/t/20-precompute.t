#!perl -T

use Test::More tests => 2;
use Math::Prime::TiedArray;
use strict;

ok(
    (
        tie my @a, "Math::Prime::TiedArray",
        precompute     => 100,
        extend_ceiling => 100
    ),
    "Tied with precompute"
);

is_deeply(
    [@a],
    [
        qw/2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97/
    ],
    "Primes lower than 100 found"
);

