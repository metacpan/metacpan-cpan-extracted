
use strict;
use warnings;
use Math::Decimal64 qw(:all);

print "1..5\n";

# Tests 1 & 2 are really only meaningful on a system where 'double' and 'long double' are both 8 bytes.
# On such a system, a value such as 9999999977777777 exceeds long double precision, and we want to
# check that MEtoD64 (which assigns using the strtold function) handles this situation correctly.

my $d64_1 = MEtoD64('99999999', 8);
my $d64_2 = MEtoD64('77777777', 0);

my $d64_3 = $d64_1 + $d64_2;

if($d64_3 == MEtoD64('9999999977777777', 0)) {print "ok 1\n"}
else {
  warn "$d64_3 != ", MEtoD64('9999999977777777', 0), "\n";
  print "not ok 1\n";
}

if($d64_3 == MEtoD64('+9999999977777777', 0)) {print "ok 2\n"}
else {
  warn "$d64_3 != ", MEtoD64('+9999999977777777', 0), "\n";
  print "not ok 2\n";
}

my $d64 = MEtoD64('-99999999', 18) + MEtoD64('-77777777', 10);

if($d64 == MEtoD64('-9999999977777777', 10)) {print "ok 3\n"}
else {
  warn "$d64 != ", MEtoD64('-9999999977777777', 10), "\n";
  print "not ok 3\n";
}

# Tests 4 and 5 check that leading zeroes don't cause incorrect behaviour.

my $d64_4 = MEtoD64('00000123', 25);

if($d64_4 == MEtoD64('123', 25)) {print "ok 4\n"}
else {
  warn "$d64_4 != ", MEtoD64('123', 25), "\n";
  print "not ok 4\n";
}

my $d64_5 = MEtoD64('00000123', -25);

if($d64_5 == MEtoD64('123', -25)) {print "ok 5\n"}
else {
  warn "$d64_5 != ", MEtoD64('123', -25), "\n";
  print "not ok 5\n";
}

