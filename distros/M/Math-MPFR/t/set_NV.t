use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;

print "1..10\n";

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

if($Config{nvtype} eq '__float128') {
  my $nv_max = 1.18973149535723176508575932662800702e4932;
  my $max = Rmpfr_init2(113);
  Rmpfr_set_NV($max, $nv_max, MPFR_RNDN);
  if($max == $nv_max) {print "ok 7\n"}
  else {
    warn "\n\$max: $max\n\$nv_max: $nv_max\n";
    print "not ok 7\n";
  }
  if(!Rmpfr_cmp_NV($max, $nv_max)) {print "ok 8\n"}
  else {
    warn "\nRmpfr_cmp_NV() returned", Rmpfr_cmp_NV($max, $nv_max), "\nExpected 0\n";
    print "not ok 8\n";
  }

  my $nv_small_neg = -2.75423489483742700033038566794997947e-4928;
  my $small_neg = Rmpfr_init2(113);
  Rmpfr_set_NV($small_neg, $nv_small_neg, MPFR_RNDN);
  if($small_neg == $nv_small_neg) {print "ok 9\n"}
  else {
    warn "\n\$small_neg: $small_neg\n\$nv_small_neg: $nv_small_neg\n";
    print "not ok 9\n";
  }
  if(!Rmpfr_cmp_NV($small_neg, $nv_small_neg)) {print "ok 10\n"}
  else {
    warn "\nRmpfr_cmp_NV() returned", Rmpfr_cmp_NV($small_neg, $nv_small_neg), "\nExpected 0\n";
    print "not ok 10\n";
  }
}
else {
  warn "\nSkipping tests 7 to 10 - NV is not __float128\n";
  print "ok 7\nok 8\nok 9\nok 10\n";
}
