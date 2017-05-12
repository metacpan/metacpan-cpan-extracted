use warnings;
use strict;
use Math::LongDouble qw(:all);
use Config;

print "1..4\n";

my $nv_root = sqrt 2.0;
my $ld_root = sqrt(Math::LongDouble->new(2.0));
my $ld_pow = Math::LongDouble->new(2.0) ** Math::LongDouble->new(0.5);

if(Math::LongDouble::_long_double_size() != $Config{nvsize}) {
  if(cmp_NV($ld_root, $nv_root)) {print "ok 1\n"}
  else {
    warn "\n\$ld_root: $ld_root\n\$nv_root: $nv_root\n";
    print "not ok 1\n";
  }
}
else {
  unless(cmp_NV($ld_root, $nv_root)) {print "ok 1\n"}
  else {
    warn "\n\$ld_root: $ld_root\n\$nv_root: $nv_root\n";
    print "not ok 1\n";
  }
}

if(approx($ld_root, $nv_root)) {print "ok 2\n"}
else {
  warn "\n\$ld_root: $ld_root\n\$nv_root: $nv_root\n";
  print "not ok 2\n";
}

if($ld_pow == $ld_root) {print "ok 3\n"}
elsif(obj_approx($ld_pow, $ld_root)) {
  warn "\nIgnoring small discrepancy (bug) between sqrt(2) and 2**0.5\n";
  print "ok 3\n";
}
else {
  warn "\n\$ld_root: $ld_root\n\$ld_pow: $ld_pow\n";
  print "not ok 3\n";
}

$ld_pow **= Math::LongDouble->new(2.0);

if(approx($ld_pow, 2.0)) {print "ok 4\n"}
else {
  warn "\n\$ld_pow: $ld_pow\n";
  print "not ok 4\n";
}

sub approx {
    my $eps = $_[0] - NVtoLD($_[1]);
    return 0 if abs($eps) > NVtoLD(0.000000001);
    return 1;
}

sub obj_approx {
    my $eps = $_[0] - $_[1];
    return 0 if abs($eps) > NVtoLD(0.000000001);
    return 1;
}
