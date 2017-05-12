use strict;
use warnings;
use Math::Decimal64 qw(:all);

print "1..2\n";

my $d64 = Math::Decimal64->new();

assignNV($d64, 123456789.5);

if($d64 == MEtoD64('1234567895', -1)) {print "ok 1\n"}
else {
  warn "$d64 != ", MEtoD64('1234567895', -1), "\n";
  print "not ok 1\n";
}

assignNV($d64, -123456789.5);

if($d64 == MEtoD64('-1234567895', -1)) {print "ok 2\n"}
else {
  warn "$d64 != ", MEtoD64('1234567895', -1), "\n";
  print "not ok 2\n";
}
