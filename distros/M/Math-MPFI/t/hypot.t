use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..1\n";

Rmpfr_set_default_prec(150);

my $mpfi = Math::MPFI->new(15);
my $mpfr = Math::MPFR->new(15);

my $mpfi2 = Math::MPFI->new(12);
my $mpfr2 = Math::MPFR->new(12);

Rmpfr_hypot($mpfr, $mpfr, $mpfr2, GMP_RNDN);
Rmpfi_hypot($mpfi, $mpfi, $mpfi2);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 1\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 1\n";
}

