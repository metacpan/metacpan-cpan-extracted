use strict;
use warnings;
use Math::Decimal128 qw(:all);

print "1..10\n";

my $orig = MEtoD128('17', -1); # 1.7
my $next = $orig * 30;

if($next == 51) {print "ok 1\n"}
else {
  warn "\n1: expected 51, got $next\n";
  print "not ok 1\n";
}

$next /= 30;
if($next == $orig) {print "ok 2\n"}
else {
  warn "\n2: Expected 17e-1, got $next\n";
  print "not ok 2\n";
}

if($next == 51 / MEtoD128('30', 0)) {print "ok 3\n"}
else {
  warn "\n3: Got ", 51 / MEtoD128('30', 0), "\n";
  print "not ok 3\n";
}

$next *= 30;
if($next == 51) {print "ok 4\n"}
else {
  warn "\n4: Expected 51, got $next\n";
  print "not ok 4\n";
}

$next /= 30;

$next += 9;

if($next == MEtoD128('107', -1)) {print "ok 5\n"}
else {
  warn "\n5: Expected 107e-1, got $next\n";
  print "not ok 5\n";
}

$next -= 9;

if($next == $orig) {print "ok 6\n"}
else {
  warn "\n6: Expected 17e-1, got $next\n";
  print "not ok 6\n";
}

if($orig * - 1 == -$next) {print "ok 7\n"}
else {
  warn "\n7: Expected -17e-1, got $next\n";
  print "not ok 7\n";
}

my $new = 3 - $orig;

if($new == MEtoD128('13', -1)) {print "ok 8\n"}
else {
  warn "\n8: Expected 13e-1, got $new\n";
  print "not ok 8\n";
}

if($new + 5 == MEtoD128('63', -1)) {print "ok 9\n"}
else {
  warn "\n9: Expected 63e-1, got ", $new + 5, "\n";
  print "not ok 9\n";
}

$new -= -5;

if($new == MEtoD128('63', -1)) {print "ok 10\n"}
else {
  warn "\n10: Expected 63e-1, got $new\n";
  print "not ok 10\n";
}
