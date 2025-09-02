use strict;
use warnings;
use Math::FakeBfloat16 qw(:all);

use Test::More;

for(5e-41, 6e-41, 7e-41, 8e-41, 9e-41) {
   cmp_ok(Math::FakeBfloat16->new(10e-41), '==', Math::FakeBfloat16->new($_), "10e-41 == $_ (NV)");
   cmp_ok(Math::FakeBfloat16->new(10e-41), '==', Math::FakeBfloat16->new(Math::MPFR->new($_)), "10e-41 == $_ (MPFR from NV)");
   cmp_ok(Math::FakeBfloat16->new(4e-41 ), '!=', Math::FakeBfloat16->new($_), "4e-41 != $_ (NV)");
   cmp_ok(Math::FakeBfloat16->new(4e-41 ), '!=', Math::FakeBfloat16->new(Math::MPFR->new($_)), "4e-41 != $_ (MPFR from NV)");
}

for ('5e-41', '6e-41', '7e-41', '8e-41', '9e-41') {
   cmp_ok(Math::FakeBfloat16->new(10e-41), '==', Math::FakeBfloat16->new($_), "10e-41 == $_ (PV)");
   cmp_ok(Math::FakeBfloat16->new(10e-41), '==', Math::FakeBfloat16->new(Math::MPFR->new($_)), "10e-41 == $_ (MPFR from PV)");
   cmp_ok(Math::FakeBfloat16->new(4e-41 ), '!=', Math::FakeBfloat16->new($_), "4e-41 != $_ (PV)");
   cmp_ok(Math::FakeBfloat16->new(4e-41 ), '!=', Math::FakeBfloat16->new(Math::MPFR->new($_)), "4e-41 != $_ (MPFR from PV)");
}

cmp_ok(Math::FakeBfloat16->new(4e-41), '==', 0, '4e-41 is zero');

# Test that Math::MPFR::subnormalize_generic
# fixes a known double-rounding anomaly.
# Requires that the __bf16 type is available
# to Math::MPFR.
if(Math::MPFR::_have_bfloat16()) {
  my $s = '13.75e-41';
  my $round = 0; # MPFR_RNDN
  my $mpfr_anom1 = Math::MPFR::Rmpfr_init2(8);
  Math::MPFR::Rmpfr_strtofr($mpfr_anom1, $s, 10, 0); # RNDN
  my $anom1 = Math::FakeBfloat16->new($s);
  cmp_ok(unpack_bf16_hex($anom1), 'eq', '0001', "direct assignment results in '0001'");
  cmp_ok(Math::MPFR::unpack_bfloat16($mpfr_anom1, $round), 'eq', '0002', "indirect assignment results in '0002'");
  cmp_ok($anom1, '!=', Math::FakeBfloat16->new($mpfr_anom1), "double-checked: values are different");
  my $mpfr_anom2 = Math::MPFR::subnormalize_generic($s, -132, 128, 8);
  cmp_ok(Math::MPFR::unpack_bfloat16($mpfr_anom2, $round), 'eq', '0001', "Math::MPFR::subnormalize_generic() ok");
  cmp_ok($anom1, '==', Math::FakeBfloat16->new($mpfr_anom2), "double-checked: values are equivalent");
}


done_testing();
