use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..8\n";

my ($have_gmpq, $have_gmpz, $have_gmp) = (0, 0, 0);
my ($mpq, $mpz, $gmp);
my $quad;
my $str = '0.5';
my $double = 0.5;
my $ui = ~0;
my $si = (($ui - 1) / 2) * -1;
my $fr = Math::MPFR->new(76543);
my $nan = Rmpfr_get_d(Math::MPFR->new(), GMP_RNDN);
my $mpfi_nan = Math::MPFI->new();
my $mpfi_inf = Math::MPFI->new(Math::MPFR->new(1) / Math::MPFR->new(0));
my $prec = 95;

Rmpfi_set_default_prec($prec);

eval{require Math::GMPq;};
unless($@) {$have_gmpq = 1}

eval{require Math::GMPz;};
unless($@) {$have_gmpz = 1}

eval{require Math::GMP;};
unless($@) {$have_gmp = 1}

if($have_gmpq) {$mpq = Math::GMPq->new('21/2')}
if($have_gmpz) {$mpz = Math::GMPz->new(98765)}
if($have_gmp)  {$gmp = Math::GMP->new(87654)}

########################################## TEST 1

my $ok = '';

if($] eq '5.008') {
  warn "Skipping 1a on this build of perl as it may be that NaN == NaN\n";
  $ok .= 'a';
}
else {
  if($nan != $nan) {$ok .= 'a'}
  else { warn "1a: nan == nan on this perl\n"}
}

if(Rmpfi_cmp($mpfi_nan, $mpfi_nan) == 1) {$ok .= 'b'}
else {warn "1b: Got ", Rmpfi_cmp($mpfi_nan, $mpfi_nan), "\nExpected 1\n"}

if(Rmpfi_cmp_d($mpfi_nan, $double) == 1) {$ok .= 'c'}
else {warn "1c: Got ", Rmpfi_cmp_d($mpfi_nan, $double), "\nExpected 1\n"}

if(Rmpfi_cmp_ui($mpfi_nan, $ui) == 1) {$ok .= 'd'}
else {warn "1d: Got ", Rmpfi_cmp_ui($mpfi_nan, $ui), "\nExpected 1\n"}

if(Rmpfi_cmp_si($mpfi_nan, $si) == 1) {$ok .= 'e'}
else {warn "1e: Got ", Rmpfi_cmp_si($mpfi_nan, $si), "\nExpected 1\n"}

if($have_gmpq) {
 if(Rmpfi_cmp_q($mpfi_nan, $mpq) == 1) {$ok .= 'f'}
 else {warn "1f: Got ", Rmpfi_cmp_q($mpfi_nan, $mpq), "\nExpected 1\n"}
}
else {
  warn "Skipping test 1f - no Math::GMPq";
  $ok .= 'f';
}

if($have_gmpz) {
 if(Rmpfi_cmp_z($mpfi_nan, $mpz) == 1) {$ok .= 'g'}
 else {warn "1g: Got ", Rmpfi_cmp_z($mpfi_nan, $mpz), "\nExpected 1\n"}
}
else {
  warn "Skipping test 1g - no Math::GMPz";
  $ok .= 'g';
}

if($have_gmp) {
 if(Rmpfi_cmp_z($mpfi_nan, $gmp) == 1) {$ok .= 'h'}
 else {warn "1h: Got ", Rmpfi_cmp_z($mpfi_nan, $gmp), "\nExpected 1\n"}
}
else {
  warn "Skipping test 1h - no Math::GMP";
  $ok .= 'h';
}

if(Rmpfi_cmp_fr($mpfi_nan, $fr) == 1) {$ok .= 'i'}
else {warn "1i: Got ", Rmpfi_cmp_fr($mpfi_nan, $fr), "\nExpected 1\n"}

if(Rmpfi_cmp_d($mpfi_nan, $nan) == 1) {$ok .= 'j'}
else {warn "1j: Got ", Rmpfi_cmp_d($mpfi_nan, $nan), "\nExpected 1\n"}

if($ok eq 'abcdefghij') {print "ok 1\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 1\n";
}

########################################## TEST 2

$ok = '';

my $mpfi = Math::MPFI->new(0.5);

unless(Rmpfi_cmp($mpfi, $mpfi)) {$ok .= 'a'}
else {
  warn "2a: Got: ", Rmpfi_cmp($mpfi, $mpfi), "\nExpected 0\n";
}

if(Rmpfi_cmp($mpfi, $mpfi + 1) < 0) {$ok .= 'b'}
else {
  warn "2b: Got: ", Rmpfi_cmp($mpfi, $mpfi + 1), "\nExpected a negative number\n";
}

if(Rmpfi_cmp($mpfi + 1, $mpfi) > 0) {$ok .= 'c'}
else {
  warn "2c: Got: ", Rmpfi_cmp($mpfi+ 1, $mpfi), "\nExpected a positive number\n";
}

unless(Rmpfi_cmp_d($mpfi, $double)) {$ok .= 'd'}
else {
  warn "2d: Got: ", Rmpfi_cmp_d($mpfi, $double), "\nExpected 0\n";
}

if(Rmpfi_cmp_d($mpfi, $double + 1) < 0) {$ok .= 'e'}
else {
  warn "2e: Got: ", Rmpfi_cmp_d($mpfi, $double + 1), "\nExpected a negative number\n";
}

if(Rmpfi_cmp_d($mpfi + 1, $double) > 0) {$ok .= 'f'}
else {
  warn "2f: Got: ", Rmpfi_cmp_d($mpfi+ 1, $double), "\nExpected a positive number\n";
}

Rmpfi_set_ui($mpfi, ~1);

unless(Rmpfi_cmp_ui($mpfi, ~1)) {$ok .= 'g'}
else {
  warn "2g: Got: ", Rmpfi_cmp_ui($mpfi, ~1), "\nExpected 0\n";
}

if(Rmpfi_cmp_ui($mpfi, $ui) < 0) {$ok .= 'h'}
else {
  warn "2h: Got: ", Rmpfi_cmp_ui($mpfi, $ui), "\nExpected a negative number\n";
}

if(Rmpfi_cmp_ui($mpfi + 1, ~1) > 0) {$ok .= 'i'}
else {
  warn "2i: Got: ", Rmpfi_cmp_ui($mpfi + 1, ~1), "\nExpected a positive number\n";
}

Rmpfi_set_si($mpfi, $si + 1);

unless(Rmpfi_cmp_si($mpfi, $si + 1)) {$ok .= 'j'}
else {
  warn "2j: Got: ", Rmpfi_cmp_si($mpfi, $si + 1), "\nExpected 0\n";
}

if(Rmpfi_cmp_si($mpfi, $si + 2) < 0) {$ok .= 'k'}
else {
  warn "2k: Got: ", Rmpfi_cmp_si($mpfi, $si + 2), "\nExpected a negative number\n";
}

if(Rmpfi_cmp_si($mpfi, $si) > 0) {$ok .= 'l'}
else {
  warn "2l: Got: ", Rmpfi_cmp_si($mpfi, $si), "\nExpected a positive number\n";
}

if($have_gmpq) {
  Rmpfi_set_q($mpfi, $mpq);

  unless(Rmpfi_cmp_q($mpfi, $mpq)) {$ok .= 'm'}
  else {
    warn "2m: Got: ", Rmpfi_cmp_q($mpfi, $mpq), "\nExpected 0\n";
  }

  if(Rmpfi_cmp_q($mpfi, $mpq + 1) < 0) {$ok .= 'n'}
  else {
    warn "2n: Got: ", Rmpfi_cmp_q($mpfi, $mpq + 1), "\nExpected a negative number\n";
  }

  if(Rmpfi_cmp_q($mpfi, $mpq - 1) > 0) {$ok .= 'o'}
  else {
    warn "2o: Got: ", Rmpfi_cmp_q($mpfi, $mpq - 1), "\nExpected a positive number\n";
  }
}
else {
  warn "Skipping tests 2m, 2n, 2o - no Math::GMPq\n";
  $ok .= 'mno';
}

if($have_gmpz) {
  Rmpfi_set_z($mpfi, $mpz);

  unless(Rmpfi_cmp_z($mpfi, $mpz)) {$ok .= 'p'}
  else {
    warn "2p: Got: ", Rmpfi_cmp_z($mpfi, $mpz), "\nExpected 0\n";
  }

  if(Rmpfi_cmp_z($mpfi, $mpz + 1) < 0) {$ok .= 'q'}
  else {
    warn "2q: Got: ", Rmpfi_cmp_z($mpfi, $mpz + 1), "\nExpected a negative number\n";
  }

  if(Rmpfi_cmp_z($mpfi, $mpz - 1) > 0) {$ok .= 'r'}
  else {
    warn "2r: Got: ", Rmpfi_cmp_z($mpfi, $mpz - 1), "\nExpected a positive number\n";
  }
}
else {
  warn "Skipping tests 2p, 2q, 2r - no Math::GMPz\n";
  $ok .= 'pqr';
}

if($have_gmp) {
  Rmpfi_set_z($mpfi, $gmp);

  unless(Rmpfi_cmp_z($mpfi, $gmp)) {$ok .= 's'}
  else {
    warn "2s: Got: ", Rmpfi_cmp_z($mpfi, $gmp), "\nExpected 0\n";
  }

  if(Rmpfi_cmp_z($mpfi, $gmp + 1) < 0) {$ok .= 't'}
  else {
    warn "2t: Got: ", Rmpfi_cmp_z($mpfi, $gmp + 1), "\nExpected a negative number\n";
  }

  if(Rmpfi_cmp_z($mpfi, $gmp - 1) > 0) {$ok .= 'u'}
  else {
    warn "2u: Got: ", Rmpfi_cmp_z($mpfi, $gmp - 1), "\nExpected a positive number\n";
  }
}
else {
  warn "Skipping tests 2s, 2t, 2u - no Math::GMP\n";
  $ok .= 'stu';
}

Rmpfi_set_fr($mpfi, $fr);

unless(Rmpfi_cmp_fr($mpfi, $fr)) {$ok .= 'v'}
else {
  warn "2v: Got: ", Rmpfi_cmp_fr($mpfi, $fr), "\nExpected 0\n";
}

if(Rmpfi_cmp_fr($mpfi, $fr + 1) < 0) {$ok .= 'w'}
else {
  warn "2w: Got: ", Rmpfi_cmp_fr($mpfi, $fr + 1), "\nExpected a negative number\n";
}

if(Rmpfi_cmp_fr($mpfi, $fr - 1) > 0) {$ok .= 'x'}
else {
  warn "2x: Got: ", Rmpfi_cmp_fr($mpfi, $fr - 1), "\nExpected a positive number\n";
}

if($ok eq 'abcdefghijklmnopqrstuvwx') {print "ok 2\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 2\n";
}

########################################## TEST 3

$ok = '';

if(!Rmpfi_is_pos(Math::MPFI->new('0'))) {$ok .= 'a'}
if(!Rmpfi_is_strictly_pos(Math::MPFI->new('0'))) {$ok .= 'b'}
if(Rmpfi_is_nonneg(Math::MPFI->new('0'))) {$ok .= 'c'}
if(!Rmpfi_is_neg(Math::MPFI->new('0'))) {$ok .= 'd'}
if(!Rmpfi_is_strictly_neg(Math::MPFI->new('0'))) {$ok .= 'e'}
if(Rmpfi_is_nonpos(Math::MPFI->new('0'))) {$ok .= 'f'}
if(Rmpfi_is_zero(Math::MPFI->new('0'))) {$ok .= 'g'}
if(Rmpfi_has_zero(Math::MPFI->new('0'))) {$ok .= 'h'}
if(!Rmpfi_nan_p(Math::MPFI->new('0'))) {$ok .= 'i'}
if(!Rmpfi_inf_p(Math::MPFI->new('0'))) {$ok .= 'j'}
if(Rmpfi_bounded_p(Math::MPFI->new('0'))) {$ok .= 'k'}

if($ok eq 'abcdefghijk') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3\n";
}

########################################## TEST 4

$ok = '';

if(Rmpfi_is_pos(Math::MPFI->new('1'))) {$ok .= 'a'}
if(Rmpfi_is_strictly_pos(Math::MPFI->new('1'))) {$ok .= 'b'}
if(Rmpfi_is_nonneg(Math::MPFI->new('1'))) {$ok .= 'c'}
if(!Rmpfi_is_neg(Math::MPFI->new('1'))) {$ok .= 'd'}
if(!Rmpfi_is_strictly_neg(Math::MPFI->new('1'))) {$ok .= 'e'}
if(!Rmpfi_is_nonpos(Math::MPFI->new('1'))) {$ok .= 'f'}
if(!Rmpfi_is_zero(Math::MPFI->new('1'))) {$ok .= 'g'}
if(!Rmpfi_has_zero(Math::MPFI->new('10'))) {$ok .= 'h'}
if(!Rmpfi_nan_p(Math::MPFI->new('10'))) {$ok .= 'i'}
if(!Rmpfi_inf_p(Math::MPFI->new('10'))) {$ok .= 'j'}
if(Rmpfi_bounded_p(Math::MPFI->new('10'))) {$ok .= 'k'}

if($ok eq 'abcdefghijk') {print "ok 4\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 4\n";
}

########################################## TEST 5

$ok = '';

if(!Rmpfi_is_pos(Math::MPFI->new('-1'))) {$ok .= 'a'}
if(!Rmpfi_is_strictly_pos(Math::MPFI->new('-1'))) {$ok .= 'b'}
if(!Rmpfi_is_nonneg(Math::MPFI->new('-1'))) {$ok .= 'c'}
if(Rmpfi_is_neg(Math::MPFI->new('-1'))) {$ok .= 'd'}
if(Rmpfi_is_strictly_neg(Math::MPFI->new('-1'))) {$ok .= 'e'}
if(Rmpfi_is_nonpos(Math::MPFI->new('-1'))) {$ok .= 'f'}
if(!Rmpfi_is_zero(Math::MPFI->new('-1'))) {$ok .= 'g'}
if(!Rmpfi_has_zero(Math::MPFI->new('-10'))) {$ok .= 'h'}
if(!Rmpfi_nan_p(Math::MPFI->new('-10'))) {$ok .= 'i'}
if(!Rmpfi_inf_p(Math::MPFI->new('-10'))) {$ok .= 'j'}
if(Rmpfi_bounded_p(Math::MPFI->new('-10'))) {$ok .= 'k'}

if($ok eq 'abcdefghijk') {print "ok 5\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 5\n";
}

########################################## TEST 6

$ok = '';

if(!Rmpfi_is_pos($mpfi_nan)) {$ok .= 'a'}
if(!Rmpfi_is_strictly_pos($mpfi_nan)) {$ok .= 'b'}
if(!Rmpfi_is_nonneg($mpfi_nan)) {$ok .= 'c'}
if(!Rmpfi_is_neg($mpfi_nan)) {$ok .= 'd'}
if(!Rmpfi_is_strictly_neg($mpfi_nan)) {$ok .= 'e'}
if(!Rmpfi_is_nonpos($mpfi_nan)) {$ok .= 'f'}
if(!Rmpfi_is_zero($mpfi_nan)) {$ok .= 'g'}
if(!Rmpfi_has_zero($mpfi_nan)) {$ok .= 'h'}
if(Rmpfi_nan_p($mpfi_nan)) {$ok .= 'i'}
if(!Rmpfi_inf_p($mpfi_nan)) {$ok .= 'j'}
if(!Rmpfi_bounded_p($mpfi_nan)) {$ok .= 'k'}

if($ok eq 'abcdefghijk') {print "ok 6\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 6\n";
}

########################################## TEST 7

$ok = '';

if(Rmpfi_is_pos($mpfi_inf)) {$ok .= 'a'}
if(Rmpfi_is_strictly_pos($mpfi_inf)) {$ok .= 'b'}
if(Rmpfi_is_nonneg($mpfi_inf)) {$ok .= 'c'}
if(!Rmpfi_is_neg($mpfi_inf)) {$ok .= 'd'}
if(!Rmpfi_is_strictly_neg($mpfi_inf)) {$ok .= 'e'}
if(!Rmpfi_is_nonpos($mpfi_inf)) {$ok .= 'f'}
if(!Rmpfi_is_zero($mpfi_inf)) {$ok .= 'g'}
if(!Rmpfi_has_zero($mpfi_inf)) {$ok .= 'h'}
if(!Rmpfi_nan_p($mpfi_inf)) {$ok .= 'i'}
if(Rmpfi_inf_p($mpfi_inf)) {$ok .= 'j'}
if(!Rmpfi_bounded_p($mpfi_inf)) {$ok .= 'k'}

if($ok eq 'abcdefghijk') {print "ok 7\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 7\n";
}

########################################## TEST 8

$ok = '';
$mpfi_inf *= -1;

if(!Rmpfi_is_pos($mpfi_inf)) {$ok .= 'a'}
if(!Rmpfi_is_strictly_pos($mpfi_inf)) {$ok .= 'b'}
if(!Rmpfi_is_nonneg($mpfi_inf)) {$ok .= 'c'}
if(Rmpfi_is_neg($mpfi_inf)) {$ok .= 'd'}
if(Rmpfi_is_strictly_neg($mpfi_inf)) {$ok .= 'e'}
if(Rmpfi_is_nonpos($mpfi_inf)) {$ok .= 'f'}
if(!Rmpfi_is_zero($mpfi_inf)) {$ok .= 'g'}
if(!Rmpfi_has_zero($mpfi_inf)) {$ok .= 'h'}
if(!Rmpfi_nan_p($mpfi_inf)) {$ok .= 'i'}
if(Rmpfi_inf_p($mpfi_inf)) {$ok .= 'j'}
if(!Rmpfi_bounded_p($mpfi_inf)) {$ok .= 'k'}

if($ok eq 'abcdefghijk') {print "ok 8\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 8\n";
}

$mpfi_inf *= -1; # return $mpfi_inf to +inf.



