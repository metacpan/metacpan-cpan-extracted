use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..7\n";

Rmpfi_set_default_prec(50);

my $r = sqrt(2);
my $op = sqrt(Math::MPFI->new(2));
my $rop = Math::MPFI->new();
my $ui = 4;
my $si = - 3;

#print $op, "\n";

if($r == $op) {print "ok 1\n"}
else {
  warn "\$op: $op\n\$r: $r\n";
  print "not ok 1\n";
}

Rmpfi_mul_2exp($rop, $op, $ui);

if($rop == $r * (2 ** $ui)) {print "ok 2\n"}
else {
  warn "\$rop: $rop\n\$r * (2 ** $ui): ", $r * (2 ** $ui), "\n";
  print "not ok 2\n";
}

Rmpfi_mul_2ui($rop, $op, $ui);

if($rop == $r * (2 ** $ui)) {print "ok 3\n"}
else {
  warn "\$rop: $rop\n\$r * (2 ** $ui): ", $r * (2 ** $ui), "\n";
  print "not ok 3\n";
}

Rmpfi_mul_2si($rop, $op, $si);

if($rop == $r * (2 ** $si)) {print "ok 4\n"}
else {
  warn "\$rop: $rop\n\$r * (2 ** $si): ", $r * (2 ** $si), "\n";
  print "not ok 4\n";
}

################################################
################################################

Rmpfi_div_2exp($rop, $op, $ui);

if($rop == $r / (2 ** $ui)) {print "ok 5\n"}
else {
  warn "\$rop: $rop\n\$r / (2 ** $ui): ", $r / (2 ** $ui), "\n";
  print "not ok 5\n";
}

Rmpfi_div_2ui($rop, $op, $ui);

if($rop == $r / (2 ** $ui)) {print "ok 6\n"}
else {
  warn "\$rop: $rop\n\$r / (2 ** $ui): ", $r / (2 ** $ui), "\n";
  print "not ok 6\n";
}

Rmpfi_div_2si($rop, $op, $si);

if($rop == $r / (2 ** $si)) {print "ok 7\n"}
else {
  warn "\$rop: $rop\n\$r / (2 ** $si): ", $r / (2 ** $si), "\n";
  print "not ok 7\n";
}
