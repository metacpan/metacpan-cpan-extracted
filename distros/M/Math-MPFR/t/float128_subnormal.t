
use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Config;

if($Config{nvtype} ne '__float128') {
  warn "\n skipping all tests - nvtype is not __float128\n";
  print "1..1\n";
  print "ok 1\n";
  exit 0;
}

print "1..50\n";

my $str = '0.1e-16494';

my $op = Rmpfr_init2(64);
my $pmin_op = Math::MPFR->new('0.1e-16493', 2);
my $z_op = Math::MPFR->new(0);

my $z = 0.0;
my $pmin = 6.475175119438025110924438958227646552e-4966;
my $ret;

Rmpfr_set_str($op, $str, 2, MPFR_RNDZ);

$ret = Rmpfr_get_NV($op, MPFR_RNDA);

if($ret == $pmin_op && $ret == $pmin) {print "ok 1\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 1\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDN);

if($ret == $z && $ret == $z_op) {print "ok 2\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 2\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDD);

if($ret == $z && $ret == $z_op) {print "ok 3\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 3\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDU);

if($ret == $pmin_op && $ret == $pmin) {print "ok 4\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 4\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDZ);

if($ret == $z && $ret == $z_op) {print "ok 5\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 5\n";
}

###############################

$op *= -1;

$ret = Rmpfr_get_NV($op, MPFR_RNDA);

if($ret == -$pmin_op && $ret == -$pmin) {print "ok 6\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 6\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDN);

if($ret == $z && $ret == $z_op) {print "ok 7\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 7\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDU);

if($ret == $z && $ret == $z_op) {print "ok 8\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 8\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDD);

if($ret == -$pmin_op && $ret == -$pmin) {print "ok 9\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 9\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDZ);

if($ret == $z && $ret == $z_op) {print "ok 10\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 10\n";
}

###############################
###############################

$str = '0.11e-16494';
Rmpfr_set_str($op, $str, 2, MPFR_RNDZ);

$ret = Rmpfr_get_NV($op, MPFR_RNDA);

if($ret == $pmin_op && $ret == $pmin) {print "ok 11\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 11\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDN);

if($ret == $pmin_op && $ret == $pmin) {print "ok 12\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 12\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDD);

if($ret == $z && $ret == $z_op) {print "ok 13\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 13\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDU);

if($ret == $pmin_op && $ret == $pmin) {print "ok 14\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 14\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDZ);

if($ret == $z && $ret == $z_op) {print "ok 15\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 15\n";
}

###############################

$op *= -1;

$ret = Rmpfr_get_NV($op, MPFR_RNDA);

if($ret == -$pmin_op && $ret == -$pmin) {print "ok 16\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 16\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDN);

if($ret == -$pmin_op && $ret == -$pmin) {print "ok 17\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 17\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDU);

if($ret == $z && $ret == $z_op) {print "ok 18\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 18\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDD);

if($ret == -$pmin_op && $ret == -$pmin) {print "ok 19\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 19\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDZ);

if($ret == $z && $ret == $z_op) {print "ok 20\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 20\n";
}

###############################
###############################

$str = '0.101e-16494';
Rmpfr_set_str($op, $str, 2, MPFR_RNDZ);

$ret = Rmpfr_get_NV($op, MPFR_RNDA);

if($ret == $pmin_op && $ret == $pmin) {print "ok 21\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 21\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDN);

if($ret == $pmin_op && $ret == $pmin) {print "ok 22\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 22\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDD);

if($ret == $z && $ret == $z_op) {print "ok 23\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 23\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDU);

if($ret == $pmin_op && $ret == $pmin) {print "ok 24\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 24\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDZ);

if($ret == $z && $ret == $z_op) {print "ok 25\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 25\n";
}

###############################

$op *= -1;

$ret = Rmpfr_get_NV($op, MPFR_RNDA);

if($ret == -$pmin_op && $ret == -$pmin) {print "ok 26\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 26\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDN);

if($ret == -$pmin_op && $ret == -$pmin) {print "ok 27\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 27\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDU);

if($ret == $z && $ret == $z_op) {print "ok 28\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 28\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDD);

if($ret == -$pmin_op && $ret == -$pmin) {print "ok 29\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 29\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDZ);

if($ret == $z && $ret == $z_op) {print "ok 30\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 30\n";
}

###############################
###############################

$str = '0.1e-16500';
Rmpfr_set_str($op, $str, 2, MPFR_RNDZ);

$ret = Rmpfr_get_NV($op, MPFR_RNDA);

if($ret == $pmin_op && $ret == $pmin) {print "ok 31\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 31\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDN);

if($ret == $z && $ret == $z_op) {print "ok 32\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 32\n";
}


$ret = Rmpfr_get_NV($op, MPFR_RNDD);

if($ret == $z && $ret == $z_op) {print "ok 33\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 33\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDU);

if($ret == $pmin_op && $ret == $pmin) {print "ok 34\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 34\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDZ);

if($ret == $z && $ret == $z_op) {print "ok 35\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 35\n";
}

###############################

$str = '-0.1e-16500';
Rmpfr_set_str($op, $str, 2, MPFR_RNDZ);

$ret = Rmpfr_get_NV($op, MPFR_RNDA);

if($ret == -$pmin_op && $ret == -$pmin) {print "ok 36\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 36\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDN);

if($ret == $z && $ret == $z_op) {print "ok 37\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 37\n";
}


$ret = Rmpfr_get_NV($op, MPFR_RNDU);

if($ret == $z && $ret == $z_op) {print "ok 38\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 38\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDD);

if($ret == -$pmin_op && $ret == -$pmin) {print "ok 39\n"}
else {
  warn "\n\$ret: $ret\n\$pmin: $pmin\n\$pmin_op: $pmin_op\n";
  print "not ok 39\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDZ);

if($ret == $z && $ret == $z_op) {print "ok 40\n"}
else {
  warn "\n\$ret: $ret\n\$z: $z\n\$z_op: $z_op\n";
  print "not ok 40\n";
}

###############################
###############################

$str = '0.111e-16492';
Rmpfr_set_str($op, $str, 2, MPFR_RNDZ);

$ret = Rmpfr_get_NV($op, MPFR_RNDA);

if($ret == $pmin_op * 4.0 && $ret == $pmin * 4.0) {print "ok 41\n"}
else {
  warn "\n\$ret: $ret\n";
  print "not ok 41\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDN);

if($ret == $pmin_op * 4.0 && $ret == $pmin * 4.0) {print "ok 42\n"}
else {
  warn "\n\$ret: $ret\n";
  print "not ok 42\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDD);

if($ret == $pmin_op * 3.0 && $ret == $pmin * 3.0) {print "ok 43\n"}
else {
  warn "\n\$ret: $ret\n";
  print "not ok 43\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDU);

if($ret == $pmin_op * 4.0 && $ret == $pmin * 4.0)  {print "ok 44\n"}
else {
  warn "\n\$ret: $ret\n";
  print "not ok 44\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDZ);

if($ret == $pmin_op * 3.0 && $ret == $pmin * 3.0)  {print "ok 45\n"}
else {
  warn "\n\$ret: $ret\n";
  print "not ok 45\n";
}

###############################

$op *= -1;

$ret = Rmpfr_get_NV($op, MPFR_RNDA);

if($ret == -$pmin_op * 4.0 && $ret == -$pmin * 4.0) {print "ok 46\n"}
else {
  warn "\n\$ret: $ret\n";
  print "not ok 46\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDN);

if($ret == -$pmin_op * 4.0 && $ret == -$pmin * 4.0) {print "ok 47\n"}
else {
  warn "\n\$ret: $ret\n";
  print "not ok 47\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDU);

if($ret == -$pmin_op * 3.0 && $ret == -$pmin * 3.0) {print "ok 48\n"}
else {
  warn "\n\$ret: $ret\n";
  print "not ok 48\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDD);

if($ret == -$pmin_op * 4.0 && $ret == -$pmin * 4.0) {print "ok 49\n"}
else {
  warn "\n\$ret: $ret\n";
  print "not ok 49\n";
}

$ret = Rmpfr_get_NV($op, MPFR_RNDZ);

if($ret == -$pmin_op * 3.0 && $ret == -$pmin * 3.0) {print "ok 50\n"}
else {
  warn "\n\$ret: $ret\n";
  print "not ok 50\n";
}

###############################
###############################
