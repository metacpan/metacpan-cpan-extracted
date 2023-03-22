# MPFR_RNDF (faithful) rounding should provide the same result
# as either MPFR_RNDU rounding (up) or MPFR_RNDD rounding (down).
# We check this.

use strict;
use warnings;
use Test::More;
use Math::MPFR qw(:mpfr);

if( MPFR_VERSION_MAJOR() < 4) {
  warn " Skipping - these tests require mpfr-4.0.0\n or later, but we have only mpfr-",
       MPFR_VERSION_STRING(), "\n";
 ok('1' eq '1', "dummy test");
  done_testing();
  exit 0;
}

for my $p(40, 50, 53, 55, 60) {

  my $rop1 = Rmpfr_init2($p); # $p-bit precision
  my $rop2 = Rmpfr_init2($p); # $p-bit precision
  my $rop3 = Rmpfr_init2($p); # $p-bit precision

  for my $its (1 .. 100) {
    my $f = Math::MPFR->new(rand(256));  # 53-bit precision
    my $c = Math::MPFR->new(rand(1024)); # 53-bit precision

    $f *= -1 if $its % 2;
    $c *= -1 unless $its % 7;

    Rmpfr_add($rop1, $f, $c, MPFR_RNDF);
    Rmpfr_add($rop2, $f, $c, MPFR_RNDU);
    Rmpfr_add($rop3, $f, $c, MPFR_RNDD);

    cmp_ok( check_it($rop1, $rop2, $rop3), '==', 1, "prec $p: $f + $c");

    Rmpfr_sub($rop1, $f, $c, MPFR_RNDF);
    Rmpfr_sub($rop2, $f, $c, MPFR_RNDU);
    Rmpfr_sub($rop3, $f, $c, MPFR_RNDD);

    cmp_ok( check_it($rop1, $rop2, $rop3), '==', 1, "prec $p: $f - $c");

    Rmpfr_mul($rop1, $f, $c, MPFR_RNDF);
    Rmpfr_mul($rop2, $f, $c, MPFR_RNDU);
    Rmpfr_mul($rop3, $f, $c, MPFR_RNDD);

    cmp_ok( check_it($rop1, $rop2, $rop3), '==', 1, "prec $p: $f * $c");

    Rmpfr_div($rop1, $f, $c, MPFR_RNDF);
    Rmpfr_div($rop2, $f, $c, MPFR_RNDU);
    Rmpfr_div($rop3, $f, $c, MPFR_RNDD);

    cmp_ok( check_it($rop1, $rop2, $rop3), '==', 1, "prec $p: $f / $c");

    Rmpfr_sqr($rop1, $c, MPFR_RNDF);
    Rmpfr_sqr($rop2, $c, MPFR_RNDU);
    Rmpfr_sqr($rop3, $c, MPFR_RNDD);

    cmp_ok( check_it($rop1, $rop2, $rop3), '==', 1, "prec $p: $c ** 2");

    Rmpfr_sqrt($rop1, $c, MPFR_RNDF);
    Rmpfr_sqrt($rop2, $c, MPFR_RNDU);
    Rmpfr_sqrt($rop3, $c, MPFR_RNDD);

    if($c < 0) {
      cmp_ok( Rmpfr_nan_p($rop1), '!=', 0, "prec $p: sqrt($c)");
    }
    else {
      cmp_ok( check_it($rop1, $rop2, $rop3), '==', 1, "prec $p: sqrt($c)");
    }
  }
}


done_testing();

sub check_it {
  my($rop1, $rop2, $rop3) = (shift, shift, shift);
  return 1 if $rop1 == $rop2;
  return 1 if $rop1 == $rop3;
  return 0;
}
