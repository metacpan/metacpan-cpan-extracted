use warnings;
use strict;
use Math::Decimal128 qw(:all);
use Math::BigInt;

print "1..14\n";

my $x = Math::Decimal128->new();
my $badarg1 = 17;
my $badarg2 = Math::BigInt->new(0);

if(is_NaND128($x) && !$x && $x != $x) {print "ok 1\n"}
else {
  warn "\$x: $x\n";
  print "not ok 1\n";
}

assignMEl($x, 1623, -3);
if($x == Math::Decimal128->new(1623, -3)) {print "ok 2\n"}
else {
  warn "\$x: $x\n";
  print "not ok 2\n";
}

assignMEl($x, 1623, 0);
if($x == Math::Decimal128->new(1623, 0)) {print "ok 3\n"}
else {
  warn "\$x: $x\n";
  print "not ok 3\n";
}

assignMEl($x, 1623, 2);
if($x == Math::Decimal128->new(162300)) {print "ok 4\n"}
else {
  warn "\$x: $x\n";
  print "not ok 4\n";
}

eval {assignMEl($badarg1, 15, -5);};
if($@ =~ /Invalid 1st arg \(17\) to assignME/) {print "ok 5\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 5\n";
}

eval {assignMEl($badarg2, 15, -5);};
if($@ =~ /Invalid 1st arg \(0\) to assignME/) {print "ok 6\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 6\n";
}

assignNaNl($x);

if(is_NaND128($x)) {print "ok 7\n"}
else {
  warn "\n7: Expected a NaN, got $x\n";
  print "not ok 7\n";
}

assignInfl($x, 0);

if(is_InfD128($x) == 1) {print "ok 8\n"}
else {
  warn "\n8: Expected a positive Inf, got $x\n";
  print "not ok 8\n";
}

assignInfl($x, -1);

if(is_InfD128($x) == -1) {print "ok 9\n"}
else {
  warn "\n9: Expected a negative Inf, got $x\n";
  print "not ok 9\n";
}

assignMEl($x, '-0', 0);

if(is_ZeroD128($x) == -1) {print "ok 10\n"}
else {
  warn "\n10: Expected -0, got $x\n";
  print "not ok 10\n";
}

assignMEl($x, '12345', -2);

if($x == MEtoD128('12345', -2)) {print "ok 11\n"}
else {
  warn "\n11:Expected 123.45, got $x\n";
  print "not ok 11\n";
}

assignMEl($x, '-1', 7400);

if(is_InfD128($x) == -1) {print "ok 12\n"}
else {
  warn "\n12: Expected -Inf, got $x\n";
  print "not ok 12\n";
}

assignMEl($x, '-1', 7400);

if(is_InfD128($x) == -1) {print "ok 13\n"}
else {
  warn "\n13: Expected -Inf, got $x\n";
  print "not ok 13\n";
}

assignD128($x, PVtoD128(('9' x 17) . ('8' x 17) . 'e-6000'));

if($x == MEtoD128(('9' x 17) . ('8' x 17), -6000)) {print "ok 14\n"}
else {
  warn "\n11:Expected 9999999999999999988888888888888888e-6000, got $x\n";
  print "not ok 14\n";
}
