use strict;
use warnings;
use Math::Decimal128 qw(:all);

my $t = 15;

print "1..$t\n";

my $nan = NaND128();

if(D128toFSTR($nan) eq 'nan') {print "ok 1\n"}
else {
  warn "\nGot ", D128toFSTR($nan),"\nExpected 'nan'\n";
  print "not ok 1\n";
}

my $pinf = InfD128(1);
if(D128toFSTR($pinf) eq 'inf') {print "ok 2\n"}
else {
  warn "\nGot ", D128toFSTR($pinf), "\nExpected 'inf'\n";
  print "not ok 2\n";
}

my $ninf = InfD128(-1);
if(D128toFSTR($ninf) eq '-inf') {print "ok 3\n"}
else {
  warn "\nGot ", D128toFSTR($ninf), "\nExpected '-inf'\n";
  print "not ok 3\n";
}

my $n = MEtoD128('321', -3);
if(D128toFSTR($n) eq '0.321') {print "ok 4\n"}
else {
  warn "\nGot ", D128toFSTR($n), "\nExpected '0.321'\n";
  print "not ok 4\n";
}

$n *= -1;
if(D128toFSTR($n) eq '-0.321') {print "ok 5\n"}
else {
  warn "\nGot ", D128toFSTR($n), "\nExpected '-0.321'\n";
  print "not ok 5\n";
}

$n *= 10;
if(D128toFSTR($n) eq '-3.21') {print "ok 6\n"}
else {
  warn "\nGot ", D128toFSTR($n), "\nExpected '-3.21'\n";
  print "not ok 6\n";
}

$n *= -1;
if(D128toFSTR($n) eq '3.21') {print "ok 7\n"}
else {
  warn "\nGot ", D128toFSTR($n), "\nExpected '3.21'\n";
  print "not ok 7\n";
}

$n /= 100;
if(D128toFSTR($n) eq '0.0321') {print "ok 8\n"}
else {
  warn "\nGot ", D128toFSTR($n), "\nExpected '0.0321'\n";
  print "not ok 8\n";
}

$n *= -1;
if(D128toFSTR($n) eq '-0.0321') {print "ok 9\n"}
else {
  warn "\nGot ", D128toFSTR($n), "\nExpected '-0.0321'\n";
  print "not ok 9\n";
}

$n *= 1000000;
if(D128toFSTR($n) eq '-32100') {print "ok 10\n"}
else {
  warn "\nGot ", D128toFSTR($n), "\nExpected '-32100'\n";
  print "not ok 10\n";
}

$n *= -1;
if(D128toFSTR($n) eq '32100') {print "ok 11\n"}
else {
  warn "\nGot ", D128toFSTR($n), "\nExpected '32100'\n";
  print "not ok 11\n";
}

my $ok = 1;

for my $exp(0..20) {
  for my $digits(1..14) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    my $float = D128toFSTR($d128);
    if(PVtoD128($float) != $d128) {
      $ok = 0;
      warn "\n  (man, exp): ($man, $exp)\n";
      warn "  MEtoD128: $d128\n  PVtoD128: $float\n";
    }
  }
}

if($ok) {print "ok 12\n"}
else {print "not ok 12\n"}

$ok = 1;

for my $exp(0..20) {
  for my $digits(1..14) {
    my $man = random_select($digits);
    my $d128 = MEtoD128("-$man", $exp);
    my $float = D128toFSTR($d128);
    if(PVtoD128($float) != $d128) {
      $ok = 0;
      warn "\n  (man, exp): (-$man, $exp)\n";
      warn "  MEtoD128: $d128\n  PVtoD128: $float\n";
    }
  }
}

if($ok) {print "ok 13\n"}
else {print "not ok 13\n"}

$ok = 1;

for my $exp(0..33) {
  for my $digits(1..15) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    my $float = D128toFSTR($d128);
    if(PVtoD128($float) != $d128) {
      $ok = 0;
      warn "\n  (man, exp): ($man, -$exp)\n";
      warn "  MEtoD128: $d128\n  PVtoD128: $float\n";
    }
  }
}

if($ok) {print "ok 14\n"}
else {print "not ok 14\n"}

$ok = 1;

for my $exp(0..33) {
  for my $digits(1..15) {
    my $man = random_select($digits);
    my $d128 = MEtoD128("-$man", -$exp);
    my $float = D128toFSTR($d128);
    if(PVtoD128($float) != $d128) {
      $ok = 0;
      warn "\n  (man, exp): (-$man, -$exp)\n";
      warn "  MEtoD128: $d128\n  PVtoD128: $float\n";
    }
  }
}

if($ok) {print "ok 15\n"}
else {print "not ok 15\n"}

$ok = 1;

sub random_select {
  my $ret = '';
  for(1 .. $_[0]) {
    $ret .= int(rand(10));
  }
  return "$ret";
}
