#!perl -T

use Test::More tests => 7;    # no_plan => 1; #
use Math::Prime::TiedArray;
use Data::Dumper;

tie my @a, "Math::Prime::TiedArray";

# shift and extend
is( shift @a, 2,  "2 shifted" );
is( shift @a, 3,  "3 shifted" );
is( shift @a, 5,  "5 shifted" );
is( shift @a, 7,  "7 shifted" );
is( $a[9],    29, "10th prime is 29" );
is( $a[8],    23, "9th prime is 23" );
is( $a[49],  229, "50th prime is 229" );

