use warnings;
use strict;
use Math::LongDouble qw(:all);
use Config;

print "1..8\n";

my $nan = NaNLD();
my $zero = ZeroLD(-1);
my $unity = UnityLD(1);
my $inf = InfLD(-1);

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
my $ld = Math::LongDouble->new('0.625');

if(cmp_NV($ld, $nv) == 0) {print "ok 5\n"}
else {
  warn "\n\$ld: $ld\n\$nv: $nv\n";
  print "not ok 5\n";
}

if(sqrt(Math::LongDouble->new(81)) == Math::LongDouble->new(9)) {print "ok 6\n"}
else {
  warn "sqrt(81): ", sqrt(Math::LongDouble->new(81)), "\n";
  print "not ok 6\n";
}

$ld = sqrt($ld);
$nv = sqrt($nv);

if(Math::LongDouble::_long_double_size() != $Config{nvsize}) {
  my $cmp = cmp_NV($ld, $nv);
  if($cmp) {print "ok 7\n"}
  else {
    warn "\nIF\n\$ld: $ld\n\$nv: $nv\n";
    warn "NaN detected\n" unless defined $cmp;
    print "not ok 7\n";
  }
}
else {
  my $cmp = cmp_NV($ld, $nv);
  if(!$cmp && defined($cmp)) {print "ok 7\n"}
  else {
    warn "\nELSE\n\$ld: $ld\n\$nv: $nv\n";
    warn "NaN detected\n" unless defined $cmp;
    print "not ok 7\n";
  }
}

my $ok = 1;

for(-10 .. 10) {
  my $ld = Math::LongDouble->new($_);
  my $ldg = $ld + Math::LongDouble->new('0.000000001');
  my $ldl = $ld - Math::LongDouble->new('0.000000001');
  unless(cmp_NV($ld, $_) == 0) {
    warn "n\ld: $ld\n\$_: $_\n";
    $ok = 0;
  }

  unless(cmp_NV($ldg, $_) == 1) {
    warn "n\ldg: $ldg\n\$_: $_\n";
    $ok = 0;
  }

  unless(cmp_NV($ldl, $_) == -1) {
    warn "n\ldl: $ldl\n\$_: $_\n";
    $ok = 0;
  }
}

if($ok) {print "ok 8\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok\n";
}
