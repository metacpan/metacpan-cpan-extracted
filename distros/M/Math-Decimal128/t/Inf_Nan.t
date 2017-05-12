use strict;
use warnings;
use Math::Decimal128 qw(:all);

print "1..4\n";

my $rop = Math::Decimal128->new('4', 0);

if($rop == 4) {print "ok 1\n"}
else {
  warn "\n \$rop: $rop\n";
  print "not ok 1\n";
}

assignInfl($rop, -1);

if($rop == InfD128(-1)) {print "ok 2\n"}
else {
  warn "\n \$rop: $rop\n";
  print "not ok 2\n";
}

assignNaNl($rop);

if(is_NaND128($rop)) {print "ok 3\n"}
else {
  warn "\n \$rop: $rop\n";
  print "not ok 3\n";
}

assignInfl($rop, 0);

if($rop == InfD128(1)) {print "ok 4\n"}
else {
  warn "\n \$rop: $rop\n";
  print "not ok 4\n";
}
