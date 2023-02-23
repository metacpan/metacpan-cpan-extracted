use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..2\n";

my $x = Math::MPFI->new(12);
my $t = Math::MPFI->new(25);
my $y = Math::MPFI->new();

Rmpfi_set($y, $t); # Checking that Rmpfi_set works correctly.

if($x == 12 && $y == 25) {print "ok 1\n"}
else {
  warn "\$x: $x\n\$y: $y\n";
  print "not ok 1\n";
}

Rmpfi_swap($x, $y);

if($y == 12 && $x == 25) {print "ok 2\n"}
else {
  warn "\$x: $x\n\$y: $y\n";
  print "not ok 2\n";
}
