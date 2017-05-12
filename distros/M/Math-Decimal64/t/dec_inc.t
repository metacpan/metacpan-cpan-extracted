use warnings;
use strict;
use Math::Decimal64 qw(:all);

print "1..2\n";

my $d64 = NVtoD64(0.625);

$d64++;
if($d64 == NVtoD64(1.625)) {print "ok 1\n"}
else {
  warn "\nLHS: $d64\nRHS: ", NVtoD64(1.231), "\n";
  print "not ok 1\n";
}

$d64--;
if($d64 == NVtoD64(0.625)) {print "ok 2\n"}
else {
  warn "\nLHS: $d64\nRHS: ", NVtoD64(0.231), "\n";
  print "not ok 2\n";
}



