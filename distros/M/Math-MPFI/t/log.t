use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..8\n";

Rmpfi_set_default_prec(50);

my $rop = Math::MPFI->new();
my $op = Math::MPFI->new(50);

Rmpfi_log($rop, $op);

if($rop == log(50)) {print "ok 1\n"}
else {
  warn "\$rop: $rop\nlog(50): ", log(50), "\n";
  print "not ok 1\n";
}

Rmpfi_set_d($op, 5.75);

Rmpfi_exp($rop, $op);

if($rop == exp(5.75)) {print "ok 2\n"}
else {
  warn "\$rop: $rop\nexp(5.75): ", exp(5.75), "\n";
  print "not ok 2\n";
}

Rmpfi_exp2($rop, $op);

if($rop == 2 ** 5.75) {print "ok 3\n"}
else {
  warn "\$rop: $rop\n2 ** 5.75: ", 2 ** 5.75, "\n";
  print "not ok 3\n";
}

Rmpfi_expm1($rop, $op);

if($rop == exp(5.75) - 1) {print "ok 4\n"}
else {
  warn "\$rop: $rop\nexp(5.75) - 1: ", exp(5.75) - 1, "\n";
  print "not ok 4\n";
}

Rmpfi_set_ui($op, 50);

Rmpfi_log1p($rop, $op);

if($rop == log(51)) {print "ok 5\n"}
else {
  warn "\$rop: $rop\nlog(51): ", log(51), "\n";
  print "not ok 5\n";
}

Rmpfi_log2($rop, $op);

if($rop == _log2(50)) {print "ok 6\n"}
else {
  warn "\$rop: $rop\nlog2(50): ", _log2(50), "\n";
  print "not ok 6\n";
}

Rmpfi_log10($rop, $op);

if($rop == _log10(50)) {print "ok 7\n"}
else {
  warn "\$rop: $rop\nlog10(50): ", _log10(50), "\n";
  print "not ok 7\n";
}

Rmpfi_const_log2($rop);

if($rop == log(2)) {print "ok 8\n"}
else {
  warn "\$rop: $rop\nlog(2): ", log(2), "\n";
  print "not ok 8\n";
}

sub _log10 {
    my $n = shift;
    return log($n)/log(10);
}

sub _log2 {
    my $n = shift;
    return log($n)/log(2);
}
