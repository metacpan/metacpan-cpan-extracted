use strict;
use warnings;
use Config;
use Math::NV qw(:all);

print "1..1\n";

my $prec = mant_dig();

if($Config{nvsize} == 8) {
  if($prec == 53) {print "ok 1\n"}
  else {
    warn "\nExpected 53\nGot $prec\n";
    print "not ok 1\n";
  }
}
elsif($Config{nvtype} eq '__float128') {
  if($prec == 113) {print "ok 1\n"}
  else {
    warn "\nExpected 113\nGot $prec\n";
    print "not ok 1\n";
  }
}
else {
  if($prec == 113 || $prec == 106 || $prec == 64) {print "ok 1\n"}
  else {
    warn "\nExpected either 113 or 106 or 64\nGot $prec\n";
    print "not ok 1\n";
  }
}

warn "\n\$Config{nvtype} is $Config{nvtype} and mantissa precision is $prec bits\n";
