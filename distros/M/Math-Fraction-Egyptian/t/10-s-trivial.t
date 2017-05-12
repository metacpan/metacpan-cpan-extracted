use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use_ok('Math::Fraction::Egyptian');

local *s_trivial = \&Math::Fraction::Egyptian::s_trivial;

my @expansions = (
    [ 1, 9 => 0, 1, 9 ],      # 1/9 => 0/1 + E(9)
);

# 1/9 expands trivially to 0/1 + 1/9
is_deeply([s_trivial(1,9)],[0,1,9]);

# the "trivial" algorithm does not apply to 2/9
throws_ok { s_trivial(2,9) } qr/unsuitable strategy/;

