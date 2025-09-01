use strict;
use warnings;

use Math::FakeFloat16 qw(:all);

use Test::More;

cmp_ok($Math::FakeFloat16::VERSION, '==', 0.01, "We have Math-FakeFloat16-0.01");
cmp_ok(Math::MPFR::RMPFR_PREC_MIN, '==', Math::FakeFloat16::MPFR_PREC_MIN, "MPFR_PREC_MIN setting is consistent");

warn "\n # MPFR_PREC_MIN: ", Math::FakeFloat16::MPFR_PREC_MIN, "\n";


done_testing();
