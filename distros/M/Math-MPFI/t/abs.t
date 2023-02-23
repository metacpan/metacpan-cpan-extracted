use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..4\n";

my $op = Math::MPFI->new();
my $rop = Math::MPFI->new();

Rmpfi_union($op, Math::MPFI->new(-10), Math::MPFI->new(25));

if($op == -9) {print "ok 1\n"}
else {
  warn "\$op ($op) does not contain -9\n";
  print "not ok 1\n";
}

Rmpfi_abs($rop, $op);

unless($rop == -9) {print "ok 2\n"}
else {
  warn "\$rop ($rop) contains -9\n";
  print "not ok 2\n";
}

if($rop == 0) {print "ok 3\n"}
else {
  warn "\$rop ($rop) does not contain 0\n";
  print "not ok 3\n";
}

my $check = abs($op);

if($check == $rop) {print "ok 4\n"}
else {
  warn "\$check: $check\n\$rop: $rop\n";
  print "not ok 4\n";
}
