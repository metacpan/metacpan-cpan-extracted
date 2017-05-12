use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';

use_ok('Math::Fraction::Egyptian');

local *is_practical = \&Math::Fraction::Egyptian::is_practical;

# test some practical numbers
my @practical = (
    1, 2, 4, 6, 8, 12, 16, 18, 20, 24, 28, 30, 32, 36, 40, 42, 48, 54,
    5000, 6120
);
for (@practical) {
    ok(is_practical($_),"$_ is practical");
}

# test some non-practical numbers
my @not_practical = (3, 5, 10, 14, 22, 136, 5004, 6008);
for (@not_practical) {
    ok(!is_practical($_),"$_ is not practical");
}

