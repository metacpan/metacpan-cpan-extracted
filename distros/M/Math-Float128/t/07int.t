use warnings;
use strict;
use Math::Float128 qw(:all);

print "1..6\n";

my $nan = NaNF128();
my $zero = ZeroF128(1);
my $nzero = ZeroF128(-1);
my $unity = UnityF128(1);
my $nunity = UnityF128(-1);
my $inf = InfF128(1);
my $ninf = InfF128(-1);

if(is_NaNF128(int($nan))) {print "ok 1\n"}
else {print "not ok 1\n"}

if(is_ZeroF128(int($zero)) && is_ZeroF128(int($nzero))) {print "ok 2\n"}
else {
  warn "int(\$zero): ", int($zero), "\nint(\$nzero): ", int($nzero), "\n";
  print "not ok 2\n";
}

if(is_InfF128(int($inf)) && is_InfF128(int($ninf))) {print "ok 3\n"}
else {print "not ok 3\n"}

if(int($unity) == UnityF128(1) && int($nunity) == UnityF128(-1)) {print "ok 4\n"}
else {print "not ok 4\n"}

my $nv = 1.6253;

if(int(NVtoF128($nv)) == UnityF128(1) &&
   int(NVtoF128($nv * -1.0)) == UnityF128(-1)) {print "ok 5\n"}
else {
  warn "int(NVtoF128(\$nv)): ",int(NVtoF128($nv)), "\n";
  print "not ok 5\n";
}

$nv = 0.6257;

if(is_ZeroF128(int(NVtoF128($nv))) > 0 &&
   is_ZeroF128(int(NVtoF128($nv * -1.0))) < 0) {print "ok 6\n"}
else {
  warn "int(NVtoF128(\$nv)): ", int(NVtoF128($nv)), "\n";
  warn "int(NVtoF128(\$nv * -1.0)): ", int(NVtoF128($nv * -1.0)), "\n";
  print "not ok 6\n";
}

