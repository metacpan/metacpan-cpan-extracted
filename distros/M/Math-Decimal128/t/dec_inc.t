use warnings;
use strict;
use Math::Decimal128 qw(:all);

print "1..2\n";

my $d128 = NVtoD128(0.625);

$d128++;
if($d128 == NVtoD128(1.625)) {print "ok 1\n"}
else {
  warn "\nLHS: $d128\nRHS: ", NVtoD128(1.231), "\n";
  print "not ok 1\n";
}

$d128--;
if($d128 == NVtoD128(0.625)) {print "ok 2\n"}
else {
  warn "\nLHS: $d128\nRHS: ", NVtoD128(0.231), "\n";
  print "not ok 2\n";
}



