# Test script for:
# mpfr_trigamma - new in 4.3.0 (version 262912)

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Test::More;

my ($inex, $x, $y) = ('hello', Math::MPFR->new(), Math::MPFR->new());

Rmpfr_set_inf($y, -1);
Rmpfr_set_inf($x,  1);

eval { $inex = Rmpfr_trigamma($y, $x, MPFR_RNDN);};

if(MPFR_VERSION >= 262912) {
  cmp_ok($inex            , '==', 0, "result of trigamma(+Inf) is exact");
  cmp_ok(Rmpfr_zero_p($y) , '!=', 0, "trigamma(+Inf) set to zero");
  cmp_ok(Rmpfr_signbit($y), '==', 0, "trigamma(+Inf) signbit is unset");

}
else {
  like($@, qr/^Rmpfr_trigamma function not implemented until mpfr\-4\.3\.0/, "trigamma() croaks as expected");
}

done_testing();
