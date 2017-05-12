
use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Math::MPFI qw(:mpfi);

print "1..1\n";

unless(Math::MPFR::_can_pass_float128()) {
  warn "\nSkipping all tests - Rmpfr_set_float128() not available\n";
  print "ok 1\n";
  exit 0;
}

my $c1 = Rmpfr_init2(113);
my $c2 = Rmpfr_init2(113);

my $c3 = Rmpfr_init2(150);
my $c4 = Rmpfr_init2(150);

my $c5 = Rmpfr_init2(50);
my $c6 = Rmpfr_init2(50);

my $ok = 1;

for(1.117e310, -1.1232e-320, (2 ** 200) + (2 ** 101), (2 ** 201) - (2 ** 100),
    999**(999**999), (999**(999**999)) * -1) {

  Rmpfr_set_float128($c1, $_, MPFR_RNDN);
  Math::MPFI::_my_mpfr_set_float128($c2, $_, MPFR_RNDN);

  Rmpfr_set_float128($c3, $_, MPFR_RNDN);
  Math::MPFI::_my_mpfr_set_float128($c4, $_, MPFR_RNDN);

  Rmpfr_set_float128($c5, $_, MPFR_RNDN);
  Math::MPFI::_my_mpfr_set_float128($c6, $_, MPFR_RNDN);

  if($c1 != $c2) {
    $ok = 0;
    warn "\n \$c1: $c1\n \$c2: $c2\n";
  }

  if($c3 != $c4) {
    $ok = 0;
    warn "\n \$c3: $c3\n \$c4: $c4\n";
  }

  if($c5 != $c6) {
    $ok = 0;
    warn "\n \$c5: $c5\n \$c6: $c6\n";
  }

}

if($ok) {print "ok 1\n"}
else    {print "not ok 1\n"}
