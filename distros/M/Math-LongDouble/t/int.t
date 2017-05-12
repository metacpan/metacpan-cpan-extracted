use warnings;
use strict;
use Math::LongDouble qw(:all);

if($] < 5.008) {
  print "1..1\n";
  warn "\nSkipping all tests - int() is not overloaded on perl-$]\n";
  print "ok 1\n";
  exit 0;
}

print "1..6\n";

my $nan = NaNLD();
my $nnan = NaNLD();
my $zero = ZeroLD(1);
my $nzero = ZeroLD(-1);
my $unity = UnityLD(1);
my $nunity = UnityLD(-1);
my $inf = InfLD(1);
my $ninf = InfLD(-1);

if(is_NaNLD(int($nan)) && is_NaNLD(int($nnan))) {print "ok 1\n"}
else {print "not ok 1\n"}

if(is_ZeroLD(int($zero)) && is_ZeroLD(int($nzero))) {print "ok 2\n"}
else {
  warn "int(\$zero): ", int($zero), "\nint(\$nzero): ", int($nzero), "\n";
  print "not ok 2\n";
}

if(is_InfLD(int($inf)) && is_InfLD(int($ninf))) {print "ok 3\n"}
else {print "not ok 3\n"}

if(int($unity) == UnityLD(1) && int($nunity) == UnityLD(-1)) {print "ok 4\n"}
else {print "not ok 4\n"}

my $nv = 1.6253;

if(int(NVtoLD($nv)) == UnityLD(1) &&
   int(NVtoLD($nv * -1.0)) == UnityLD(-1)) {print "ok 5\n"}
else {
  warn "int(NVtoLD(\$nv)): ",int(NVtoLD($nv)), "\n";
  print "not ok 5\n";
}

$nv = 0.6257;

if(is_ZeroLD(int(NVtoLD($nv))) > 0) {
  if(is_ZeroLD(int(NVtoLD($nv * -1.0))) < 0) {print "ok 6\n"}
  elsif(is_ZeroLD(int(NVtoLD($nv * -1.0)))) {
    warn "\nIgnoring that ceill(-0.6257) returned '0' instead of '-0'\n";
    print "ok 6\n";
  }
  else {
    warn "\nIF: int(NVtoLD(\$nv)): ", int(NVtoLD($nv)), "\n";
    warn "IF: int(NVtoLD(\$nv * -1.0)): ", int(NVtoLD($nv * -1.0)), "\n";
    print "not ok 6\n";
  }
}
else {
  warn "\nELSE: int(NVtoLD(\$nv)): ", int(NVtoLD($nv)), "\n";
  warn "ELSE: int(NVtoLD(\$nv * -1.0)): ", int(NVtoLD($nv * -1.0)), "\n";
  print "not ok 6\n";
}

