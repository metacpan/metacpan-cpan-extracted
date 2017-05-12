use strict;
use warnings;
use Math::MPFR qw(:mpfr);

print "1..6\n";

Rmpfr_set_default_prec(120);

my $fr1 = Rmpfr_init();
my $fr2 = Rmpfr_init();
my ($ret1, $ret2);

my $inf = 999**(999**999);
my $nan = $inf / $inf;
my $ninf = $inf * -1;

$ret1 = Rmpfr_set_NV($fr1, sqrt(3.0), MPFR_RNDN);

if(Math::MPFR::_has_longdouble() && !Math::MPFR::_nv_is_float128()) {
  $ret2 = Rmpfr_set_ld($fr2, sqrt(3.0), MPFR_RNDN);
}
elsif(Math::MPFR::_can_pass_float128()) {
  $ret2 = Rmpfr_set_float128($fr2, sqrt(3.0), MPFR_RNDN);
}
elsif(Math::MPFR::_nv_is_float128()) {
  $ret2 = Rmpfr_set_NV($fr2, sqrt(3.0), MPFR_RNDN); # tests 1 & 2 are bound to succeed
}
else {
  $ret2 = Rmpfr_set_d($fr2, sqrt(3.0), MPFR_RNDN);
}

if($fr1 == $fr2) {print "ok 1\n"}
else {
  warn "\n\$fr1: $fr1\n\$fr2: $fr2\n";
  print "not ok 1\n";
}

if($ret1 == $ret2) {print "ok 2\n"}
else {
  warn "\n\$ret1: $ret1\n\$ret2: $ret2\n";
  print "not ok 2\n";
}

if($fr1 == sqrt(3.0) && $fr2 == sqrt(3.0)) {print "ok 3\n"}
else {
  warn "\n$fr1: $fr1\n\$fr2: $fr2\nsqrt(3.0): ", sqrt(3.0), "\n";
  print "not ok 3\n";
}

Rmpfr_set_NV($fr1, $nan, MPFR_RNDN);

if($fr1 != $fr1) {print "ok 4\n"}
else {
  warn "\n Expected NaN, got $fr1\n";
  print "not ok 4\n";
}

Rmpfr_set_NV($fr1, $inf, MPFR_RNDN);

if(Rmpfr_inf_p($fr1) && $fr1 > 0) {print "ok 5\n"}
else {
  warn "\n Expected Inf, got $fr1\n";
  print "not ok 5\n";
}

Rmpfr_set_NV($fr1, $ninf, MPFR_RNDN);

if(Rmpfr_inf_p($fr1) && $fr1 < 0) {print "ok 6\n"}
else {
  warn "\n Expected -Inf, got $fr1\n";
  print "not ok 6\n";
}
