use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..6\n";

my $op = Math::MPFI->new();
my $fr = Math::MPFR->new();

Rmpfi_union($op, Math::MPFI->new(-11), Math::MPFI->new(29));

#print $op;

Rmpfi_diam_abs($fr, $op);

if($fr == 40) {print "ok 1\n"}
else {
  warn "\$fr: $fr\n\$op: $op\n";
  print "not ok 1\n";
}

Rmpfi_diam_rel($fr, $op);

if($fr > 4.44444444444444 && $fr < 4.44444444444445) {print "ok 2\n"}
else {
  warn "\$fr: $fr\n\$op: $op\n";
  print "not ok 2\n";
}

Rmpfi_diam($fr, $op);

if($fr == 40) {print "ok 3\n"}
else {
  warn "\$fr: $fr\n\$op: $op\n";
  print "not ok 3\n";
}

Rmpfi_mag($fr, $op);

if($fr == 29) {print "ok 4\n"}
else {
  warn "\$fr: $fr\n\$op: $op\n";
  print "not ok 4\n";
}

Rmpfi_mig($fr, $op);

if($fr == 0) {print "ok 5\n"}
else {
  warn "\$fr: $fr\n\$op: $op\n";
  print "not ok 5\n";
}

Rmpfi_mid($fr, $op);

if($fr == 9) {print "ok 6\n"}
else {
  warn "\$fr: $fr\n\$op: $op\n";
  print "not ok 6\n";
}
