use strict;
use warnings;
use Math::Decimal128 qw(:all);

print "1..4\n";

if(Exp10l(-6176) > ZeroD128(0)) {print "ok 1\n"}
 else {
   warn "\n Exp10l(-6176): ", Exp10l(-6176), "\n";
   warn " Zero: ", ZeroD128(0), "\n";
   print "not ok 1\n";
}

if(Exp10l(-6177) == ZeroD128(0)) {print "ok 2\n"}
 else {
   warn "\n Exp10l(-6177): ", Exp10l(-6177), "\n";
   warn " Zero: ", ZeroD128(0), "\n";
   print "not ok 2\n";
}

if(Exp10l(6144) < InfD128(0)) {print "ok 3\n"}
 else {
   warn "\n Exp10l(6144): ", Exp10l(6144), "\n";
   warn " Inf: ", InfD128(0), "\n";
   print "not ok 3\n";
}

if(Exp10l(6145) == InfD128(0)) {print "ok 4\n"}
 else {
   warn "\n Exp10l(6145): ", Exp10l(6145), "\n";
   warn " Inf: ", InfD128(0), "\n";
   print "not ok 4\n";
}
