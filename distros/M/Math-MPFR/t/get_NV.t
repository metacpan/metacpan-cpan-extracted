use strict;
use warnings;
use Math::MPFR qw(:mpfr);

my $inf = 999**(999**999);
my $nan =  $inf / $inf;
my $real = -93.0176;

if($nan == $nan) {
  warn "\nSkippping all tests - buggy inf and/or nan implementation on this perl\n";
  print "1..1\n";
  print "ok 1\n";
  exit 0;
}

print "1..10\n";

Rmpfr_set_default_prec(200);

my $check = Rmpfr_get_NV(Math::MPFR->new($inf), MPFR_RNDN);
if($check == $inf) {print "ok 1\n"}
else {
  warn "\n Expected $inf, Got $check\n";
  print "not ok 1\n";
}

$check = Rmpfr_get_NV(Math::MPFR->new($nan), MPFR_RNDN);
if($check != $check) {print "ok 2\n"}
else {
  warn "\n Expected NaN, Got $check\n";
  print "not ok 2\n";
}

$check = Rmpfr_get_NV(Math::MPFR->new($real), MPFR_RNDN);
if($check == $real) {print "ok 3\n"}
else {
  warn "\n Expected $real, Got $check\n";
  print "not ok 3\n";
}

$check = Rmpfr_get_NV(Math::MPFR->new('-1.2e4932'), MPFR_RNDN);
if($check == $check && $check != 0 && $check / $check !=1 && $check == ($inf * -1)) {print "ok 4\n"}
else {
  warn "\n Expected -Inf, Got $check\n";
  print "not ok 4\n";
}

$check = Rmpfr_get_NV(Math::MPFR->new(-2.627e123), MPFR_RNDN);
if($check == -2.627e123) {print "ok 5\n"}
else {
  warn "\n Expected -2.627e123, Got $check\n";
  print "not ok 5\n";
}

$check = Rmpfr_get_NV(Math::MPFR->new(-2.627e-123), MPFR_RNDN);
if($check == -2.627e-123) {print "ok 6\n"}
else {
  warn "\n Expected -2.627e-123, Got $check\n";
  print "not ok 6\n";
}

$check = Rmpfr_get_NV(Math::MPFR->new(2.627e123), MPFR_RNDN);
if($check == 2.627e123) {print "ok 7\n"}
else {
  warn "\n Expected 2.627e123, Got $check\n";
  print "not ok 7\n";
}

$check = Rmpfr_get_NV(Math::MPFR->new(2.627e-123), MPFR_RNDN);
if($check == 2.627e-123) {print "ok 8\n"}
else {
  warn "\n Expected 2.627e-123, Got $check\n";
  print "not ok 8\n";
}

$check = Rmpfr_get_NV(Math::MPFR->new('-6.2e-4967'), MPFR_RNDN);
if($check == 0.0) {print "ok 9\n"}
else {
  warn "\n Expected zero, Got $check\n";
  print "not ok 9\n";
}

$check = Rmpfr_get_NV(Math::MPFR->new(), MPFR_RNDN);
if($check != $check) {print "ok 10\n"}
else {
  warn "\n Expected NaN, Got $check\n";
  print "not ok 10\n";
}
