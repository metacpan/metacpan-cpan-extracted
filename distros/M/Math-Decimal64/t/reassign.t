use warnings;
use strict;
use Math::Decimal64 qw(:all);
use Math::BigInt;

print "1..15\n";

my $x = Math::Decimal64->new();
my $badarg1 = 17;
my $badarg2 = Math::BigInt->new();

if(is_NaND64($x) && !$x && $x != $x) {print "ok 1\n"}
else {
  warn "\$x: $x\n";
  print "not ok 1\n";
}

assignME($x, 1623, -3);
if($x == Math::Decimal64->new(1623, -3)) {print "ok 2\n"}
else {
  warn "\$x: $x\n";
  print "not ok 2\n";
}

assignME($x, 1623, 0);
if($x == Math::Decimal64->new(1623, 0)) {print "ok 3\n"}
else {
  warn "\$x: $x\n";
  print "not ok 3\n";
}

assignME($x, 1623, 2);
if($x == Math::Decimal64->new(162300)) {print "ok 4\n"}
else {
  warn "\$x: $x\n";
  print "not ok 4\n";
}

eval {assignME($badarg1, 15, -5);};
if($@ =~ /Invalid 1st arg \(17\) to assignME/) {print "ok 5\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 5\n";
}

eval {assignME($badarg2, 15, -5);};
if($@ =~ /Invalid 1st arg \(0\) to assignME/) {print "ok 6\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 6\n";
}

assignNaN($x);

if(is_NaND64($x)) {print "ok 7\n"}
else {
  warn "\n7: Expected a NaN, got $x\n";
  print "not ok 7\n";
}

assignInf($x, 0);

if(is_InfD64($x) == 1) {print "ok 8\n"}
else {
  warn "\n8: Expected a positive Inf, got $x\n";
  print "not ok 8\n";
}

assignInf($x, -1);

if(is_InfD64($x) == -1) {print "ok 9\n"}
else {
  warn "\n9: Expected a negative Inf, got $x\n";
  print "not ok 9\n";
}

assignME($x, '-0', 0);

if(is_ZeroD64($x) == -1) {print "ok 10\n"}
else {
  warn "\n10: Expected -0, got $x\n";
  print "not ok 10\n";
}

assignPV($x, '12345e-2');

if($x == MEtoD64('12345', -2)) {print "ok 11\n"}
else {
  warn "\n11:Expected 123.45, got $x\n";
  print "not ok 11\n";
}

assignPV($x, '-1e400');

if(is_InfD64($x) == -1) {print "ok 12\n"}
else {
  warn "\n12: Expected -Inf, got $x\n";
  print "not ok 12\n";
}

assignME($x, '-1', 400);

if(is_InfD64($x) == -1) {print "ok 13\n"}
else {
  warn "\n13: Expected -Inf, got $x\n";
  print "not ok 13\n";
}

assignME($x,         '9999999977777777', -103);

if($x ==     MEtoD64('9999999977777777', -103)) {print "ok 14\n"}
else {
  warn "\n11:Expected 9999999977777777e-103, got $x\n";
  print "not ok 14\n";
}

assignD64($x, MEtoD64('9999999917777777', -102));

if($x == MEtoD64     ('9999999917777777', -102)) {print "ok 15\n"}
else {
  warn  "\n11:Expected 9999999917777777e-102, got $x\n";
  print "not ok 15\n";
}
