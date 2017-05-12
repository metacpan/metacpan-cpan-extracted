# Tests to check what happens when mantissas consisting of more than
# 16 decimal digits are supplied to MEtoD64.

use warnings;
use strict;
use Math::Decimal128 qw(:all);
use Devel::Peek;

print "1..3\n";

eval{Math::Decimal128->new('-1234567890123456712345678901234567', -123);};

if(!$@) {print "ok 1\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 1\n";
}

eval{Math::Decimal128->new('-12345678901234567123456789012345678', -123);};

if($@ =~ /exceeds _Decimal128 precision/) {print "ok 2\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 2\n";
}

eval{Math::Decimal128->new("-1234567.89012345", -123);};

if($@ =~ /Invalid 1st arg \(\-1234567.89012345/) {
  print "ok 3\n";
}
else {
  warn "\$\@: $@\n";
  print "not ok 3\n";
}





