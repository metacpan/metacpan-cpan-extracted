use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';

use_ok('Math::Fraction::Egyptian');

local *prime_factors = \&Math::Fraction::Egyptian::prime_factors;
local *decompose = \&Math::Fraction::Egyptian::decompose;

is_deeply(
    [ prime_factors(28) ],
    [ [2,2], [7,1] ],
    "28 => 2 * 2 * 7"
);

is_deeply( [decompose(15)], [3,5] );
is_deeply( [decompose(21)], [3,7] );
is_deeply( [decompose(28)], [4,7] );
is_deeply( [decompose(35)], [5,7] );

