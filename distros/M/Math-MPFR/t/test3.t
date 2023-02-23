# Test the functions that became available with MPFR-2.1.0.
use strict;
use warnings;
use Math::MPFR qw(:mpfr);

print "1..21\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

Rmpfr_set_default_prec(300);
my $rnd = 0;

my $double = 1234567.0987;
my $mpfr_nan = Rmpfr_init();
my $mpfr1 = Rmpfr_init();
my $mpfr2 = Rmpfr_init();
my $v;

my($have_mpz, $have_mpf, $have_mpq, $have_gmp) = (0, 0, 0, 0);

eval{require Math::GMPz};
if(!$@) {$have_mpz = 1}

eval{require Math::GMPf};
if(!$@) {$have_mpf = 1}

eval{require Math::GMPq};
if(!$@) {$have_mpq = 1}

eval{require Math::GMP};
if(!$@) {$have_gmp = 1}

Rmpfr_set_d($mpfr1, $double, $rnd);

if($have_mpz) {
  my $ok = '';
  my $z = Math::GMPz::Rmpz_init_set_ui(123456);
  my $cmp = Rmpfr_cmp_z($mpfr_nan, $z);
  if(Rmpfr_erangeflag_p() && !$cmp) {$ok .= 'a'}
  Rmpfr_clear_erangeflag();
  if(!Rmpfr_erangeflag_p()) {$ok .= 'b'}
  if(Rmpfr_cmp_z($mpfr1, $z) > 0) {$ok .= 'c'}
  my $ret = Rmpfr_get_z($z, $mpfr1, $rnd);
  if(MPFR_VERSION_MAJOR >= 3) {
    if(defined($ret)) {$ok .= 'D'}
  }
  else {
    if(!defined($ret)) {$ok .= 'D'}
  }
  Rmpfr_trunc($mpfr1, $mpfr1);
  if(!Rmpfr_cmp_z($mpfr1, $z)) {$ok .= 'd'}
  Rmpfr_set_d($mpfr1, $double, $rnd);
  if($ok eq 'abcDd') {print "ok 1\n"}
  else {print "not ok 1 $ok\n"}
}
else {
  warn "Skipping test 1 - no Math::GMPz\n";
  print "ok 1\n";
}

if($have_mpq) {
  my $ok = '';
  my $q = Math::GMPq::Rmpq_init();
  Math::GMPq::Rmpq_set_ui($q, 11, 17);
  my $cmp = Rmpfr_cmp_q($mpfr_nan, $q);
  if(Rmpfr_erangeflag_p() && !$cmp) {$ok .= 'a'}
  Rmpfr_clear_erangeflag();
  if(!Rmpfr_erangeflag_p()) {$ok .= 'b'}
  if(Rmpfr_cmp_q($mpfr1, $q) > 0) {$ok .= 'c'}
  if($ok eq 'abc') {print "ok 2\n"}
  else {print "not ok 2 $ok\n"}
}
else {
  warn "Skipping test 2 - no Math::GMPq\n";
  print "ok 2\n";
}

if($have_mpf) {
  my $ok = '';
  my $f = Math::GMPf::Rmpf_init_set_d(123456.12);
  my $cmp = Rmpfr_cmp_f($mpfr_nan, $f);
  if(Rmpfr_erangeflag_p() && !$cmp) {$ok .= 'a'}
  Rmpfr_clear_erangeflag();
  if(!Rmpfr_erangeflag_p()) {$ok .= 'b'}
  if(Rmpfr_cmp_f($mpfr1, $f) > 0) {$ok .= 'c'}
  if($ok eq 'abc') {print "ok 3\n"}
  else {print "not ok 3 $ok\n"}
}
else {
  warn "Skipping test 3 - no Math::GMPf\n";
  print "ok 3\n";
}

if($have_gmp) {
  my $ok = '';
  my $z = Math::GMP->new(123456);
  my $cmp = Rmpfr_cmp_z($mpfr_nan, $z);
  if(Rmpfr_erangeflag_p() && !$cmp) {$ok .= 'a'}
  Rmpfr_clear_erangeflag();
  if(!Rmpfr_erangeflag_p()) {$ok .= 'b'}
  if(Rmpfr_cmp_z($mpfr1, $z) > 0) {$ok .= 'c'}
  Rmpfr_get_z($z, $mpfr1, $rnd);
  Rmpfr_trunc($mpfr1, $mpfr1);
  if(!Rmpfr_cmp_z($mpfr1, $z)) {$ok .= 'd'}
  Rmpfr_set_d($mpfr1, $double, $rnd);
  if($ok eq 'abcd') {print "ok 4\n"}
  else {print "not ok 4 $ok\n"}
}
else {
  warn "Skipping test 4 - no Math::GMP\n";
  print "ok 4\n";
}

Rmpfr_set_ui_2exp($mpfr2, 5, 3, $rnd);
if($mpfr2 == 40) {print "ok 5\n"}
else {print "not ok 5\n"}

Rmpfr_set_si_2exp($mpfr2, 5, 3, $rnd);
if($mpfr2 == 40) {print "ok 6\n"}
else {print "not ok 6\n"}

Rmpfr_set_si_2exp($mpfr2, 8, -3, $rnd);
if($mpfr2 == 1) {print "ok 7\n"}
else {print "not ok 7\n"}

Rmpfr_sub_si($mpfr2, $mpfr2, -11, $rnd);
if($mpfr2 == 12) {print "ok 8\n"}
else {print "not ok 8\n"}

Rmpfr_si_sub($mpfr2, -11, $mpfr2, $rnd);
if($mpfr2 == -23) {print "ok 9\n"}
else {print "not ok 9\n"}

Rmpfr_mul_si($mpfr2, $mpfr2, -11, $rnd);
if($mpfr2 == 253) {print "ok 10\n"}
else {print "not ok 10\n"}

Rmpfr_div_si($mpfr2, $mpfr2, -11, $rnd);
if($mpfr2 == -23) {print "ok 11\n"}
else {print "not ok 11\n"}

$mpfr2++;

Rmpfr_si_div($mpfr2, -11, $mpfr2, $rnd);
if($mpfr2 == 0.5) {print "ok 12\n"}
else {print "not ok 12\n"}

Rmpfr_mul($mpfr1, $mpfr2, $mpfr2, $rnd);
Rmpfr_sqr($mpfr2, $mpfr2, $rnd);
if($mpfr1 == $mpfr2) {print "ok 13\n"}
else {print "not ok 13\n"}

Rmpfr_const_pi($mpfr1, $rnd);
if(!Rmpfr_zero_p($mpfr1)) {print "ok 14\n"}
else {print "not ok 14\n"}

eval{Rmpfr_free_cache();};
if(!$@) {print "ok 15\n"}
else {print "not ok 15: $@\n"}

eval{$v = Rmpfr_get_version();};
if(!$@ && $v) {print "ok 16\n"}
else {print "not ok 16: $@\n"}

if((Rmpfr_get_emin_min() <= Rmpfr_get_emin_max()) &&
   (Rmpfr_get_emax_min() <= Rmpfr_get_emax_max())) {print "ok 17\n"}
else {print "not ok 17\n"}

Rmpfr_set_d($mpfr1, $double, $rnd);

Rmpfr_rint_ceil($mpfr2, $mpfr1, $rnd);
if($mpfr2 == 1234568) {print "ok 18\n"}
else {print "not ok 18\n"}

Rmpfr_rint_floor($mpfr2, $mpfr1, $rnd);
if($mpfr2 == 1234567) {print "ok 19\n"}
else {print "not ok 19\n"}

Rmpfr_rint_round($mpfr2, $mpfr1, $rnd);
if($mpfr2 == 1234567) {print "ok 20\n"}
else {print "not ok 20\n"}

Rmpfr_rint_trunc($mpfr2, $mpfr1, $rnd);
if($mpfr2 == 1234567) {print "ok 21\n"}
else {print "not ok 21\n"}
