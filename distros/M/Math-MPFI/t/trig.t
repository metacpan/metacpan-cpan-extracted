use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..21\n";

Rmpfr_set_default_prec(150);

my $mpfi = Math::MPFI->new(5);
my $mpfr = Math::MPFR->new(5);

Rmpfr_sin($mpfr, $mpfr, GMP_RNDN);
my $c1 = sin($mpfi);
Rmpfi_sin($mpfi, $mpfi);

if($c1 == $mpfi) {print "ok 1\n"}
else {
  warn "\$c1: $c1\n\$mpfi: $mpfi\n";
  print "not ok 1\n";
}

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 2\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 2\n";
}

Rmpfr_cos($mpfr, $mpfr, GMP_RNDN);
my $c2 = cos($mpfi);
Rmpfi_cos($mpfi, $mpfi);

if($c2 == $mpfi) {print "ok 3\n"}
else {
  warn "\$c2: $c2\n\$mpfi: $mpfi\n";
  print "not ok 3\n";
}

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 4\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 4\n";
}

Rmpfr_tan($mpfr, $mpfr, GMP_RNDN);
Rmpfi_tan($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 5\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 5\n";
}

########################################

Rmpfr_asin($mpfr, $mpfr, GMP_RNDN);
Rmpfi_asin($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 6\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 6\n";
}

Rmpfr_acos($mpfr, $mpfr, GMP_RNDN);
Rmpfi_acos($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 7\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 7\n";
}

Rmpfr_atan($mpfr, $mpfr, GMP_RNDN);
Rmpfi_atan($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 8\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 8\n";
}

#########################################

Rmpfr_sinh($mpfr, $mpfr, GMP_RNDN);
Rmpfi_sinh($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 9\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 9\n";
}

Rmpfr_cosh($mpfr, $mpfr, GMP_RNDN);
Rmpfi_cosh($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 10\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 10\n";
}

Rmpfr_tanh($mpfr, $mpfr, GMP_RNDN);
Rmpfi_tanh($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 11\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 11\n";
}

$mpfr += 100;
$mpfi += 100;

##########################################

Rmpfr_asinh($mpfr, $mpfr, GMP_RNDN);
Rmpfi_asinh($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 12\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 12\n";
}

Rmpfr_acosh($mpfr, $mpfr, GMP_RNDN);
Rmpfi_acosh($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 13\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 13\n";
}

$mpfr -= 2;
$mpfi -= 2;

Rmpfr_atanh($mpfr, $mpfr, GMP_RNDN);
Rmpfi_atanh($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 14\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 14\n";
}

###########################################

Rmpfr_sec($mpfr, $mpfr, GMP_RNDN);
Rmpfi_sec($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 15\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 15\n";
}

Rmpfr_csc($mpfr, $mpfr, GMP_RNDN);
Rmpfi_csc($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 16\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 16\n";
}

Rmpfr_cot($mpfr, $mpfr, GMP_RNDN);
Rmpfi_cot($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 17\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 17\n";
}

########################################

Rmpfr_sech($mpfr, $mpfr, GMP_RNDN);
Rmpfi_sech($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 18\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 18\n";
}

Rmpfr_csch($mpfr, $mpfr, GMP_RNDN);
Rmpfi_csch($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 19\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 19\n";
}

Rmpfr_coth($mpfr, $mpfr, GMP_RNDN);
Rmpfi_coth($mpfi, $mpfi);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 20\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 20\n";
}

########################################

my $mpfr2 = Math::MPFR->new(2);
my $mpfi2 = Math::MPFI->new(2);

Rmpfr_atan2($mpfr, $mpfr, $mpfr2, GMP_RNDN);
Rmpfi_atan2($mpfi, $mpfi, $mpfi2);

if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {print "ok 21\n"}
else {
  warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
  print "not ok 21\n";
}

#########################################

#print "$mpfr\n$mpfi\n";
