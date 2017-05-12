# Tests to check what happens when mantissas consisting of more than
# 16 decimal digits are supplied to MEtoD64.

use warnings;
use strict;
use Math::Decimal64 qw(:all);

print "1..3\n";

eval{Math::Decimal64->new('-1234567890123456', -123);};

if(!$@) {print "ok 1\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 1\n";
}

eval{Math::Decimal64->new('-12345678901234567', -123);};

if($@ =~ /exceeds _Decimal64 precision/) {print "ok 2\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 2\n";
}

eval{Math::Decimal64->new(-1234567.8901234567, -123);};

if($@ =~ /Invalid 1st arg \(\-1234567\.8901234/) {
  print "ok 3\n";
}
else {
  warn "\$\@: $@\n";
  print "not ok 3\n";
}





