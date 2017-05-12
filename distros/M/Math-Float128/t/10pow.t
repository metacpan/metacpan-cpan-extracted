use warnings;
use strict;
use Math::Float128 qw(:all);
use Config;

print "1..4\n";

my $nv_root = sqrt 2.0;
my $ld_root = sqrt(Math::Float128->new(2.0));
my $ld_pow = Math::Float128->new(2.0) ** Math::Float128->new(0.5);

if(cmp2NV($ld_root, $nv_root) && $Config{nvtype} ne '__float128') {print "ok 1\n"}
elsif(!cmp2NV($ld_root, $nv_root) && $Config{nvtype} eq '__float128') {print "ok 1\n"}
else {
  warn "\n\$ld_root: $ld_root\n\$nv_root: $nv_root\n";
  print "not ok 1\n";
}

if(approx($ld_root, $nv_root)) {print "ok 2\n"}
else {
  warn "\n\$ld_root: $ld_root\n\$nv_root: $nv_root\n";
  print "not ok 2\n";
}

if($ld_pow == $ld_root) {print "ok 3\n"}
else {
  warn "\n\$ld_root: $ld_root\n\$ld_pow: $ld_pow\n";
  print "not ok 3\n";
}

$ld_pow **= Math::Float128->new(2.0);

if(approx($ld_pow, 2.0)) {print "ok 4\n"}
else {
  warn "\n\$ld_pow: $ld_pow\n";
  print "not ok 4\n";
}

sub approx {
    my $eps = $_[0] - NVtoF128($_[1]);
    return 0 if abs($eps) > NVtoF128(0.000000001);
    return 1;
}
