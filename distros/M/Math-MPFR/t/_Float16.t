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
    cmp_ok(unpack_float16($nv, MPFR_RNDN), 'eq', '3DA8', 'hex unpacking of sqrt(2) is as expected');

    my $inex = Rmpfr_set_float16($op, $nv, MPFR_RNDN);
    cmp_ok($inex, '==', 0, 'value set exactly');
    cmp_ok($op, '==', $op16, 'values still match');
  }
  else {
    cmp_ok(Math::MPFR::_have_float16(), '==', 0, "MPFR library support for_Float16 is not utilised");

    my ($op, $nv) = (Math::MPFR->new(), 0);
    eval { $nv = Rmpfr_get_float16(123, MPFR_RNDN);};
    like($@, qr/^Perl interface to Rmpfr_get_float16 not available/, 'Rmpfr_get_float16: $@ set as expected');
    eval { Rmpfr_set_float16($nv, $op, MPFR_RNDN);};
    like($@, qr/^Perl interface to Rmpfr_set_float16 not available/, 'Rmpfr_set_float16: $@ set as expected');
  }
}
else {
  cmp_ok(Rmpfr_buildopt_float16_p(), '==', 0, "Rmpfr_buildopt_float16_p() returns 0");
  cmp_ok(Math::MPFR::_have_float16(), '==', 0, "_Float16 support is lacking");

  my ($op, $nv) = (Math::MPFR->new(), 0);
  eval { $nv = Rmpfr_get_float16(123, MPFR_RNDN);};
  like($@, qr/^Perl interface to Rmpfr_get_float16 not available/, 'Rmpfr_get_float16: $@ set as expected');
  eval { Rmpfr_set_float16($nv, $op, MPFR_RNDN);};
  like($@, qr/^Perl interface to Rmpfr_set_float16 not available/, 'Rmpfr_set_float16: $@ set as expected');
}

done_testing();
