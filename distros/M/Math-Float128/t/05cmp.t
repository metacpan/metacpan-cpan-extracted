use warnings;
use strict;
use Math::Float128 qw(:all);
use Config;

print "1..8\n";

my $nan = NaNF128();
my $zero = ZeroF128(-1);
my $unity = UnityF128(1);
my $inf = InfF128(-1);

# Try to determine when the decimal point is a comma,
# and set $dp accordingly.
my $dp = '.';
$dp = ',' unless Math::Float128->new('0,5') == Math::Float128->new(0);

if($nan != $nan && $nan != $zero && $nan != $unity && $nan != $inf) {print "ok 1\n"}
else {
  warn "\$nan: $nan\n\$zero: $zero\n\$unity: $unity\n\$inf: $inf\n";
  print "not ok 1\n";
}

if($zero < $unity && $zero <= $unity && $unity > $zero && $unity >= $zero) {print "ok 2\n"}
else {
  warn "\$zero: $zero\n\$unity: $unity\n";
  print "not ok 2\n";
}

if(($inf <=> $zero) < 0 && ($zero <=> $inf) > 0 && ($unity <=> $unity) == 0) {print "ok 3\n"}
else {
  warn "\$inf: $inf\n\$zero: $zero\n\$unity: $unity\n";
  print "not ok 3\n";
}

if($unity == $unity && $unity <= $unity && $unity >= $unity) {print "ok 4\n"}
else {
  warn "\$unity: $unity\n";
  print "not ok 4\n";
}

my $nv = 0.625;
my $ld = Math::Float128->new("0${dp}625");

if(cmp2NV($ld, $nv) == 0) {print "ok 5\n"}
else {
  warn "\n\$ld: $ld\n\$nv: $nv\n";
  print "not ok 5\n";
}

if(sqrt(Math::Float128->new(81)) == Math::Float128->new(9)) {print "ok 6\n"}
else {
  warn "sqrt(81): ", sqrt(Math::Float128->new(81)), "\n";
  print "not ok 6\n";
}

$ld = sqrt($ld);
$nv = sqrt($nv);

if(cmp2NV($ld, $nv) && $Config{nvtype} ne '__float128') {print "ok 7\n"}
elsif(!cmp2NV($ld, $nv) && $Config{nvtype} eq '__float128') {print "ok 7\n"}
else {
  warn "\nIF\n\$ld: $ld\n\$nv: $nv\n";
  print "not ok 7\n";
}


my $ok = 1;

for(-10 .. 10) {
  my $ld = Math::Float128->new($_);
  my $ldg = $ld + Math::Float128->new("0${dp}000000001");
  my $ldl = $ld - Math::Float128->new("0${dp}000000001");
  unless(cmp2NV($ld, $_) == 0) {
    warn "\nld: $ld\n\$_: $_\n";
    $ok = 0;
  }

  unless(cmp2NV($ldg, $_) == 1) {
    warn "\nldg: $ldg\n\$_: $_\n";
    $ok = 0;
  }

  unless(cmp2NV($ldl, $_) == -1) {
    warn "\nldl: $ldl\n\$_: $_\n";
    $ok = 0;
  }
}

if($ok) {print "ok 8\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok\n";
}
