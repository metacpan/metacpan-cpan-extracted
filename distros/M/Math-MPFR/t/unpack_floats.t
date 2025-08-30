# Mainly just a sanity check.
# For the values being tested here, it's expected that the
# subnormalize_* functions will make no difference to the
# returned value - and that the 2 strings being compared
# in these tests will therefore be identical.

use strict;
use warnings;

use Math::MPFR qw(:mpfr);

use Test::More;

my($have_gmpf, $have_gmpq) = (0, 0);
my($str1, $str2);

eval { require Math::GMPf;};
$have_gmpf = 1 unless $@;

eval { require Math::GMPq;};
$have_gmpq = 1 unless $@;

my @stuff = (-549, ~0, 303.35, '-317.85', Math::MPFR->new('1131.2') );

push @stuff, Math::GMPf->new(42.42) if $have_gmpf;
push @stuff, Math::GMPq->new('15/7') if $have_gmpq;

if(MPFR_VERSION >= 262912) { # MPFR-4.3.0 or later

  if(Math::MPFR::_have_float16()) {
    for my $arg(@stuff) {
      if(ref($arg)) {
        $str1 = unpack_float16(Math::MPFR->new($arg), MPFR_RNDN);
      }
      else {
        $str1 = unpack_float16($arg, MPFR_RNDN);
      }
      $str2 = unpack_float16(subnormalize_float16($arg), MPFR_RNDN);
      cmp_ok($str1, 'eq', $str2, "_Float16 $arg: Strings match");
    }
  }

  if(Math::MPFR::_have_bfloat16()) {
    for my $arg(@stuff) {
      if(ref($arg)) {
        $str1 = unpack_bfloat16(Math::MPFR->new($arg), MPFR_RNDN);
      }
      else {
        $str1 = unpack_bfloat16($arg, MPFR_RNDN);
      }
      $str2 = unpack_bfloat16(subnormalize_generic($arg, -132, 128, 8), MPFR_RNDN);
      cmp_ok($str1, 'eq', $str2, "__bf16 $arg: Strings match");
    }
  }
}

for my $arg(@stuff) {
  if(ref($arg)) {
    $str1 = unpack_float32(Math::MPFR->new($arg), MPFR_RNDN);
  }
  else {
    $str1 = unpack_float32($arg, MPFR_RNDN);
  }
  $str2 = unpack_float32(subnormalize_float32($arg), MPFR_RNDN);
  cmp_ok($str1, 'eq', $str2, "float32 $arg: Strings match");
}

done_testing();
