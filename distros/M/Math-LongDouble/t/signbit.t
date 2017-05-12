use strict;
use warnings;
use Math::LongDouble qw(:all);

# Not implementing signed NaNs, so we don't check that
# signbit works as expected with them.

print "1..8\n";

my $inf = InfLD(-1);

if(signbit_LD($inf)) {print "ok 1\n"}
else {
  warn "\n$inf was (unexpectedly) reported  to be +ve\n";
  print "not ok 1\n";
}

if(!signbit_LD($inf * -1)) {print "ok 2\n"}
else {
  warn "\n", $inf * -1, " was (unexpectedly) reported  to be -ve\n";
  print "not ok 2\n";
}

my $negzero = ZeroLD(-1);

if(signbit_LD($negzero)) {print "ok 3\n"}
else {
  warn "\n$negzero was (unexpectedly) reported  to be +ve\n";
  print "not ok 3\n";
}

if(!signbit_LD($negzero * -1)) {print "ok 4\n"}
else {
  warn "\n", $negzero * -1, " was (unexpectedly) reported  to be -ve\n";
  print "not ok 4\n";
}

my $zero = ZeroLD(1);

if(!signbit_LD($zero)) {print "ok 5\n"}
else {
  warn "\n$zero was (unexpectedly) reported  to be -ve\n";
  print "not ok 5\n";
}

if(signbit_LD($zero * -1)) {print "ok 6\n"}
else {
  warn "\n", $zero * -1, " was (unexpectedly) reported  to be +ve\n";
  print "not ok 6\n";
}

my $negval = Math::LongDouble->new('-2.123');

if(signbit_LD($negval)) {print "ok 7\n"}
else {
  warn "\n$negval was (unexpectedly) reported  to be +ve\n";
  print "not ok 7\n";
}

if(!signbit_LD($negval * -1)) {print "ok 8\n"}
else {
  warn "\n", $negval * -1, " was (unexpectedly) reported  to be -ve\n";
  print "not ok 8\n";
}
