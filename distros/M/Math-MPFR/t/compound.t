
# Test script for:
# mpfr_compound_si - new in 4.2.0
# mpfr_compound - new in 4.3.0

use strict;
use warnings;
use Math::MPFR qw(:mpfr);

use Test::More;

my $rop = Math::MPFR->new();

warn "MPFR_VERSION: ", MPFR_VERSION, "\n";
warn "MPFR_VERSION_STRING: ", MPFR_VERSION_STRING, "\n";

if(MPFR_VERSION >= 262656) {
  my $inex = Rmpfr_compound_si($rop, Math::MPFR->new(5), 3, MPFR_RNDN);
  cmp_ok($rop, '==', 216, "Rmpfr_compound_si: 6 ** 3 == 216");

  $inex = Rmpfr_compound_si($rop, Math::MPFR->new(-1.001), 3, MPFR_RNDN);
  cmp_ok(Rmpfr_nan_p($rop), '!=', 0, "Rmpfr_compound_si: -1.001 ** 3 is NaN");

  $inex = Rmpfr_compound_si($rop, Math::MPFR->new(), 0, MPFR_RNDN);
  cmp_ok($rop, '==', 1, "Rmpfr_compound_si: NaN ** 0 is 1");

  $inex = Rmpfr_compound_si($rop, Math::MPFR->new(-1), -1, MPFR_RNDN);
  cmp_ok((Rmpfr_inf_p($rop) && ($rop > 0)), '!=', 0, "Rmpfr_compound_si: -1 ** a negative power is +Inf");

  $inex = Rmpfr_compound_si($rop, Math::MPFR->new(-1), 1, MPFR_RNDN);
  cmp_ok((Rmpfr_zero_p($rop) && !Rmpfr_signbit($rop)), '!=', 0, "Rmpfr_compound_si: -1 ** a positive power is +0");
}
else {
  eval {Rmpfr_compound_si($rop, Math::MPFR->new(5), 0, MPFR_RNDN);};
  like($@, qr/^Rmpfr_compound_si function not implemented/, "Rmpfr_compound_si requires mpfr-4.2.0");
}

if(MPFR_VERSION >= 262912) {

  my $inex = Rmpfr_compound($rop, Math::MPFR->new(5), Math::MPFR->new(3), MPFR_RNDN);
  cmp_ok($rop, '==', 216, "Rmpfr_compound: 6 ** 3 == 216");

  $inex = Rmpfr_compound($rop, Math::MPFR->new(-1.001), Math::MPFR->new(3), MPFR_RNDN);
  cmp_ok(Rmpfr_nan_p($rop), '!=', 0, "Rmpfr_compound: -1.001 ** 3 is NaN");

  $inex = Rmpfr_compound($rop, Math::MPFR->new(), Math::MPFR->new(0), MPFR_RNDN);
  cmp_ok($rop, '==', 1, "Rmpfr_compound: NaN ** 0 is 1");

  $inex = Rmpfr_compound($rop, Math::MPFR->new(-1), Math::MPFR->new(-2.5), MPFR_RNDN);
  cmp_ok((Rmpfr_inf_p($rop) && ($rop > 0)), '!=', 0, "Rmpfr_compound: -1 ** a negative power is +Inf");

  $inex = Rmpfr_compound($rop, Math::MPFR->new(-1), Math::MPFR->new(2.5), MPFR_RNDN);
  cmp_ok((Rmpfr_zero_p($rop) && !Rmpfr_signbit($rop)), '!=', 0, "Rmpfr_compound: -1 ** a positive power is +0");
}
else {
  eval {Rmpfr_compound($rop, Math::MPFR->new(5), Math::MPFR->new(0), MPFR_RNDN);};
  like($@, qr/^Rmpfr_compound function not implemented/, "Rmpfr_compound requires mpfr-4.3.0");
}

done_testing();
