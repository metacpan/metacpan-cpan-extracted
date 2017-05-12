use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use_ok('Math::Fraction::Egyptian');

local *s_small_prime = \&Math::Fraction::Egyptian::s_small_prime;

# 2/p = 2/(p + 1) + 2/p(p + 1)
# the "small prime" algorithm does not apply to 3/10
throws_ok { s_small_prime(3,10) } qr/unsuitable strategy/;

# 2/11 => 2/12 + 2/(11)(12) = 0/1 + 1/6 + 1/66
is_deeply([s_small_prime(2,11)],[0,1,6,66]);


