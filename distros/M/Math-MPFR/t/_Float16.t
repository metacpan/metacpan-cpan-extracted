use strict;
use warnings;

use Math::MPFR qw(:mpfr);

use Test::More;

if(MPFR_VERSION >= 262912) { # MPFR-4.3.0 or later
  if(Math::MPFR::_have_float16()) {
    cmp_ok(Rmpfr_buildopt_float16_p(),  '==', 1, "MPFR library supports _Float16");
    cmp_ok(Math::MPFR::_have_float16(), '==', 1, "_Float16 support is available && utilised");

    my $op = sqrt(Math::MPFR->new(2));
    my $nv = Rmpfr_get_float16($op, MPFR_RNDN);
    cmp_ok($op, '!=', $nv, "values no longer match");

    my $op16 = Rmpfr_init2(11); # _Float16 has 11 bits of precision.
    Rmpfr_set_ui($op16, 2, MPFR_RNDN);
    Rmpfr_sqrt($op16, $op16, MPFR_RNDN);

    cmp_ok($nv, '==', $op16, "values match");
  }
  else {
    cmp_ok(Math::MPFR::_have_float16(), '==', 0, "MPFR library support for_Float16 is not utilised");
  }
}
else {
  eval{Rmpfr_buildopt_float16_p();};
  like($@, qr/'mpfr_buildopt_float16_p' not implemented until MPFR\-4\.3\.0/,
       "Rmpfr_buildopt_float16_p() croaks as expected");

  cmp_ok(Math::MPFR::_have_float16(), '==', 0, "_Float16 support is lacking");
}

done_testing();
