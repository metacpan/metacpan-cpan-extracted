use strict;
use warnings;

use Math::FakeBfloat16 qw(:all);

use Test::More;

cmp_ok($Math::FakeBfloat16::VERSION, '==', 0.01, "We have Math-FakeBfloat16-0.01");

warn "\n # MPFR_PREC_MIN: ", Math::MPFR::MPFR_PREC_MIN, "\n";


done_testing();
