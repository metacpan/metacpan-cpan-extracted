use strict;
use warnings;
use Math::Decimal64 qw(:all);

print "1..4\n";

if(Exp10(-398) > ZeroD64(0)) {print "ok 1\n"}
 else {
   warn "\n Exp10(-398): ", Exp10(-398), "\n";
   warn " Zero: ", ZeroD64(0), "\n";
   print "not ok 1\n";
}

if(Exp10(-399) == ZeroD64(0)) {print "ok 2\n"}
 else {
   warn "\n Exp10(-399): ", Exp10(-399), "\n";
   warn " Zero: ", ZeroD64(0), "\n";
   print "not ok 2\n";
}

if(Exp10(384) < InfD64(0)) {print "ok 3\n"}
 else {
   warn "\n Exp10(384): ", Exp10(384), "\n";
   warn " Inf: ", InfD64(0), "\n";
   print "not ok 3\n";
}

if(Exp10(385) == InfD64(0)) {print "ok 4\n"}
 else {
   warn "\n Exp10(385): ", Exp10(385), "\n";
   warn " Inf: ", InfD64(0), "\n";
   print "not ok 4\n";
}
