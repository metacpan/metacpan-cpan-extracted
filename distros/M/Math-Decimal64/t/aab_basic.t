use warnings;
use strict;
use Math::Decimal64 qw(:all);

print "1..4\n";


if($Math::Decimal64::VERSION eq '0.17' && Math::Decimal64::_get_xs_version() eq $Math::Decimal64::VERSION) {print "ok 1\n"}
else {print "not ok 1 $Math::Decimal64::VERSION ", Math::Decimal64::_get_xs_version(), "\n"}

my $end = Math::Decimal64::_endianness();

if(defined($end)) {
  warn "\nEndianness: $end\n";
  print "ok 2\n";
}
else {
  print "not ok 2\n";
}

my $fmt = d64_fmt();
if($fmt eq 'DPD' || $fmt eq 'BID') {
  warn "Format: $fmt\n";
  print "ok 3\n";
}

else {
  warn "Format: $fmt\n";
  print "not ok 3\n";
}

if($fmt eq $Math::Decimal64::fmt) {print "ok 4\n"}
else {
  warn "\n d64_bytes(MEtoD64('1234567890123456', 0)) is expected to be either\n",
       " 31C462D53C8ABAC0 (for BID format) or 263934B9C1E28E56 (for DPD format).\n",
       " Instead we got: ", d64_bytes(MEtoD64('1234567890123456', 0)), "\n";
  print "not ok 4\n";
}
