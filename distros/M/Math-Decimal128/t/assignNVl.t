use strict;
use warnings;
use Math::Decimal128 qw(:all);

print "1..2\n";

my $d128 = Math::Decimal128->new();

assignNVl($d128, 123456789.5);

if($d128 == MEtoD128('1234567895', -1)) {print "ok 1\n"}
else {
  warn "$d128 != ", MEtoD128('1234567895', -1), "\n";
  print "not ok 1\n";
}

assignNVl($d128, -123456789.5);

if($d128 == MEtoD128('-1234567895', -1)) {print "ok 2\n"}
else {
  warn "$d128 != ", MEtoD128('1234567895', -1), "\n";
  print "not ok 2\n";
}
