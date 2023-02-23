use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..2\n";

Rmpfr_set_default_prec(150);

my $mpfi = Math::MPFI->new(37);
my $mpfr = Math::MPFR->new(37);

Rmpfr_sqrt($mpfr, $mpfr, GMP_RNDN);
Rmpfi_sqrt($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 1\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 1\n";
}


Rmpfr_cbrt($mpfr, $mpfr, GMP_RNDN);
Rmpfi_cbrt($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 2\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 2\n";
}
