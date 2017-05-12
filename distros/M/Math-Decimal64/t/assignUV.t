use strict;
use warnings;
use Math::Decimal64 qw(:all);

print "1..1\n";

my $d64 = Math::Decimal64->new();

assignUV($d64, 123456789);

if($d64 == MEtoD64('123456789', 0)) {print "ok 1\n"}
else {
  warn "$d64 != ", MEtoD64('123456789', 0), "\n";
  print "not ok 1\n";
}

