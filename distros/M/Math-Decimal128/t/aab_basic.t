use warnings;
use strict;
use Math::Decimal128 qw(:all);
use Devel::Peek;

print "1..4\n";


if($Math::Decimal128::VERSION eq '0.08' && Math::Decimal128::_get_xs_version() eq $Math::Decimal128::VERSION) {print "ok 1\n"}
else {print "not ok 1 $Math::Decimal128::VERSION ", Math::Decimal128::_get_xs_version(), "\n"}

my $end = Math::Decimal128::_endianness();

if(defined($end)) {
  warn "\nEndianness: $end\n";
  print "ok 2\n";
}
else {
  print "not ok 2\n";
}

my $fmt = d128_fmt();
if($fmt eq 'DPD' || $fmt eq 'BID') {
  warn "Format: $fmt\n";
  print "ok 3\n";
}

else {
  warn "Format: $fmt\n";
  print "not ok 3\n";
}

if($fmt eq $Math::Decimal128::fmt) {print "ok 4\n"}
else {
  warn "\n d128_bytes(MEtoD128('1234567890123456789012345678901234', 0))\n",
       " is expected to be either:\n",
       " 30403CDE6FFF9732DE825CD07E96AFF2 (for BID format) or\n",
       " 2608134B9C1E28E56F3C127177823534 (for DPD format).\n",
       " Instead we got: ", d128_bytes(MEtoD128('1234567890123456789012345678901234', 0)), "\n";
  print "not ok 4\n";
}

