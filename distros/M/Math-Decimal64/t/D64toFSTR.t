use strict;
use warnings;
use Math::Decimal64 qw(:all);

my $t = 15;

print "1..$t\n";

my $nan = NaND64();

if(D64toFSTR($nan) eq 'nan') {print "ok 1\n"}
else {
  warn "\nGot ", D64toFSTR($nan),"\nExpected 'nan'\n";
  print "not ok 1\n";
}

my $pinf = InfD64(1);
if(D64toFSTR($pinf) eq 'inf') {print "ok 2\n"}
else {
  warn "\nGot ", D64toFSTR($pinf), "\nExpected 'inf'\n";
  print "not ok 2\n";
}

my $ninf = InfD64(-1);
if(D64toFSTR($ninf) eq '-inf') {print "ok 3\n"}
else {
  warn "\nGot ", D64toFSTR($ninf), "\nExpected '-inf'\n";
  print "not ok 3\n";
}

my $n = MEtoD64('321', -3);
if(D64toFSTR($n) eq '0.321') {print "ok 4\n"}
else {
  warn "\nGot ", D64toFSTR($n), "\nExpected '0.321'\n";
  print "not ok 4\n";
}

$n *= -1;
if(D64toFSTR($n) eq '-0.321') {print "ok 5\n"}
else {
  warn "\nGot ", D64toFSTR($n), "\nExpected '-0.321'\n";
  print "not ok 5\n";
}

$n *= 10;
if(D64toFSTR($n) eq '-3.21') {print "ok 6\n"}
else {
  warn "\nGot ", D64toFSTR($n), "\nExpected '-3.21'\n";
  print "not ok 6\n";
}

$n *= -1;
if(D64toFSTR($n) eq '3.21') {print "ok 7\n"}
else {
  warn "\nGot ", D64toFSTR($n), "\nExpected '3.21'\n";
  print "not ok 7\n";
}

$n /= 100;
if(D64toFSTR($n) eq '0.0321') {print "ok 8\n"}
else {
  warn "\nGot ", D64toFSTR($n), "\nExpected '0.0321'\n";
  print "not ok 8\n";
}

$n *= -1;
if(D64toFSTR($n) eq '-0.0321') {print "ok 9\n"}
else {
  warn "\nGot ", D64toFSTR($n), "\nExpected '-0.0321'\n";
  print "not ok 9\n";
}

$n *= 1000000;
if(D64toFSTR($n) eq '-32100') {print "ok 10\n"}
else {
  warn "\nGot ", D64toFSTR($n), "\nExpected '-32100'\n";
  print "not ok 10\n";
}

$n *= -1;
if(D64toFSTR($n) eq '32100') {print "ok 11\n"}
else {
  warn "\nGot ", D64toFSTR($n), "\nExpected '32100'\n";
  print "not ok 11\n";
}

my $ok = 1;

for my $exp(0..11) {
  for my $digits(1..5) {
    my $man = random_select($digits);
    my $d64 = MEtoD64($man, $exp);
    my $float = D64toFSTR($d64);
    if(PVtoD64($float) != $d64) {
      $ok = 0;
      warn "\n  (man, exp): ($man, $exp)\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $float\n";
    }
  }
}

if($ok) {print "ok 12\n"}
else {print "not ok 12\n"}

$ok = 1;

for my $exp(0..11) {
  for my $digits(1..5) {
    my $man = random_select($digits);
    my $d64 = MEtoD64("-$man", $exp);
    my $float = D64toFSTR($d64);
    if(PVtoD64($float) != $d64) {
      $ok = 0;
      warn "\n  (man, exp): (-$man, $exp)\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $float\n";
    }
  }
}

if($ok) {print "ok 13\n"}
else {print "not ok 13\n"}

$ok = 1;

for my $exp(0..15) {
  for my $digits(1..5) {
    my $man = random_select($digits);
    my $d64 = MEtoD64($man, -$exp);
    my $float = D64toFSTR($d64);
    if(PVtoD64($float) != $d64) {
      $ok = 0;
      warn "\n  (man, exp): ($man, -$exp)\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $float\n";
    }
  }
}

if($ok) {print "ok 14\n"}
else {print "not ok 14\n"}

$ok = 1;

for my $exp(0..15) {
  for my $digits(1..5) {
    my $man = random_select($digits);
    my $d64 = MEtoD64("-$man", -$exp);
    my $float = D64toFSTR($d64);
    if(PVtoD64($float) != $d64) {
      $ok = 0;
      warn "\n  (man, exp): (-$man, -$exp)\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $float\n";
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
