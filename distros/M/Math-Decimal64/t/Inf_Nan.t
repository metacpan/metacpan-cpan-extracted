use strict;
use warnings;
use Math::Decimal64 qw(:all);

print "1..4\n";

my $rop = Math::Decimal64->new('4', 0);

if($rop == 4) {print "ok 1\n"}
else {
  warn "\n \$rop: $rop\n";
  print "not ok 1\n";
}

assignInf($rop, -1);

if($rop == InfD64(-1)) {print "ok 2\n"}
else {
  warn "\n \$rop: $rop\n";
  print "not ok 2\n";
}

assignNaN($rop);

if(is_NaND64($rop)) {print "ok 3\n"}
else {
  warn "\n \$rop: $rop\n";
  print "not ok 3\n";
}

assignInf($rop, 0);

if($rop == InfD64(1)) {print "ok 4\n"}
else {
  warn "\n \$rop: $rop\n";
  print "not ok 4\n";
}
