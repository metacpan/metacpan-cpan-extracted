use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..1\n";

Rmpfr_set_default_prec(150);

my $mpfi = Math::MPFI->new();
my $mpfr = Math::MPFR->new();

Rmpfr_const_catalan($mpfr, GMP_RNDN);
Rmpfi_const_catalan($mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 1\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 1\n";
}
