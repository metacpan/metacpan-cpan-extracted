use strict;
use warnings;
use Math::MPFR qw(:mpfr);

print "1..2\n";

my $x = Math::MPFR->new('0.1@'. Rmpfr_get_emin(), 2);

if($x != 0 && Rmpfr_underflow_p() == 0) { print "ok 1\n" }
else {
  warn "\$x: $x\nmpfr_underflow_p(): ", Rmpfr_underflow_p(), "\n";
  print "not ok 1\n";
}

Rmpfr_clear_underflow();

my $y = Math::MPFR->new('0.1@'. (Rmpfr_get_emin() - 1), 2);

if($y == 0 && Rmpfr_underflow_p() != 0) { print "ok 2\n" }
else {
  warn "\$y: $y\nmpfr_underflow_p(): ", Rmpfr_underflow_p(), "\n";
  print "not ok 1\n";
}
