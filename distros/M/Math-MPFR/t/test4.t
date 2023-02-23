use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Config;

print "1..46\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $have_mpq = 0;
my $ok;

eval{require Math::GMPq};
if(!$@) {$have_mpq = 1}

Rmpfr_set_default_rounding_mode(GMP_RNDZ);
if(Rmpfr_get_default_rounding_mode() == GMP_RNDZ) {print "ok 1\n"}
else {print "not ok 1\n"}

Rmpfr_set_default_rounding_mode(GMP_RNDN);
if(Rmpfr_get_default_rounding_mode() == GMP_RNDN) {print "ok 2\n"}
else {print "not ok 2\n"}

Rmpfr_set_default_prec(300);
my $f = Rmpfr_init();
Rmpfr_set_d($f, 13.5, GMP_RNDN);

my $ret = Rmpfr_prec_round($f, 70, GMP_RNDN);

if($ret == 0 && $f == 13.5 && Rmpfr_get_prec($f) == 70) {print "ok 3\n"}
else {print "not ok 3\n"}

my $emin = Rmpfr_get_emin();
my $emax = Rmpfr_get_emax();

$emin++;
$emax--;

if(!Rmpfr_set_emin($emin)) {print "ok 4\n"}
else {print "not ok 4\n"}

if(!Rmpfr_set_emax($emax)) {print "ok 5\n"}
else {print "not ok 5\n"}

if(Rmpfr_get_emin() == $emin &&
   Rmpfr_get_emax() == $emax) {print "ok 6\n"}
else {print "not ok 6\n"}

$emin--;
$emax++;

if(!Rmpfr_set_emin($emin)) {print "ok 7\n"}
else {print "not ok 7\n"}

if(!Rmpfr_set_emax($emax)) {print "ok 8\n"}
else {print "not ok 8\n"}

if(Rmpfr_get_emin() == $emin &&
   Rmpfr_get_emax() == $emax) {print "ok 9\n"}
else {print "not ok 9\n"}

$ok = '';

my $fma = Rmpfr_init();
my $m = Rmpfr_init();
my $a = Rmpfr_init();

Rmpfr_set_d($m, 121.5, GMP_RNDN);
Rmpfr_set_d($a, 23.25, GMP_RNDN);

Rmpfr_fma($fma, $f, $m, $a, GMP_RNDN);

if($fma == 1663.5) {$ok .= 'a'}

Rmpfr_fms($fma, $f, $m, $a, GMP_RNDN);

if($fma == 1617) {$ok .= 'b'}

if($ok eq 'ab') {print "ok 10\n"}
else {print "not ok 10 $ok\n"}

Rmpfr_sqrt_ui($fma, 2, GMP_RNDN);

if($fma > 1.414213 && $fma < 1.414214) {print "ok 11\n"}
else {print "not ok 11\n"}

if(!Rmpfr_equal_p($fma, $m) && Rmpfr_lessgreater_p($fma, $m)) {print "ok 12\n"}
else {print "not ok 12\n"}

if(Rmpfr_lessequal_p($fma, $m) &&
   Rmpfr_less_p($fma, $m) &&
   Rmpfr_greater_p($m, $fma) &&
   Rmpfr_greaterequal_p($m, $fma)) {print "ok 13\n"}
else {print "not ok 13\n"}

Rmpfr_fac_ui($fma, 10, GMP_RNDN);

if($fma == 3628800) {print "ok 14\n"}
else {print "not ok 14\n"}

my $angle = Rmpfr_init();
my $s = Rmpfr_init();
my $c = Rmpfr_init();
Rmpfr_set_d($angle, 3.217, GMP_RNDN);

Rmpfr_sin($s, $angle, GMP_RNDN);
Rmpfr_cos($c, $angle, GMP_RNDN);
Rmpfr_pow_ui($s, $s, 2, GMP_RNDN);
Rmpfr_pow_ui($c, $c, 2, GMP_RNDN);
Rmpfr_add($s, $s, $c, GMP_RNDN);

if($s > 0.9999999 && $s < 1.00000001) {print "ok 15\n"}
else {print "not ok 15\n"}

$ret = Rmpfr_log1p($fma, $fma, GMP_RNDN);

if($ret && $fma > 15.104412848648 && $fma < 15.104412848649) {print "ok 16\n"}
else {print "not ok 16\n"}

$ret = Rmpfr_expm1($fma, $fma, GMP_RNDN);

if($ret && $fma > 3628799.99999 && $fma < 3628800.00001) {print "ok 17\n"}
else {print "not ok 17\n"}

$f *= -1;

$ret = Rmpfr_frac($f, $f, GMP_RNDN);

if(!$ret && $f == -0.5) {print "ok 18\n"}
else {print "not ok 18\n"}

my $next = Rmpfr_init();

Rmpfr_nexttoward($f, $next);
if(Rmpfr_nan_p($f)) {print "ok 19\n"}
else {print "not ok 19\n"}

Rmpfr_set_d($f, 10.5, GMP_RNDN);
Rmpfr_set_d($m, 11.5, GMP_RNDN);

Rmpfr_nexttoward($f, $m);
if($f > 10.5 && $f < 10.50001) {print "ok 20\n"}
else {print "not ok 20\n"}

Rmpfr_set_d($f, 10.5, GMP_RNDN);
Rmpfr_nextabove($f);

if($f > 10.5 && $f < 10.50001) {print "ok 21\n"}
else {print "not ok 21\n"}

Math::MPFR::Rmpfr_nextbelow($f);
if($f == 10.5) {print "ok 22\n"}
else {print "not ok 22\n"}

Rmpfr_nextabove($next);
if(Rmpfr_nan_p($next)) {print "ok 23\n"}
else {print "not ok 23\n"}

Math::MPFR::Rmpfr_nextbelow($next);
if(Rmpfr_nan_p($next)) {print "ok 24\n"}
else {print "not ok 24\n"}

$ret = Rmpfr_ui_pow_ui($fma, 7, 5, GMP_RNDN);
if(!$ret && $fma == 16807) {print "ok 25\n"}
else {print "not ok 25\n"}

Rmpfr_set_d($f, 1.23456789, GMP_RNDU);
$ret = Rmpfr_ui_pow($fma, 7, $f, GMP_RNDN);
if($ret && $fma > 11.049201764 && $fma < 11.049201765) {print "ok 26\n"}
else {print "not ok 26\n"}

$ret = Rmpfr_pow_si($fma, $f, -3, GMP_RNDN);
if($ret && $fma > 0.531441014 && $fma < 0.531441015) {print "ok 27\n"}
else {print "not ok 27\n"}

Rmpfr_set_d($f, 0.25, GMP_RNDN);
$ret = Rmpfr_cmp_ui_2exp($f, 2, -3);
if(!$ret) {print "ok 28\n"}
else {print "not ok 28\n"}

$f *= -1;

$ret = Rmpfr_cmp_si_2exp($f, -2, -3);
if(!$ret) {print "ok 29\n"}
else {print "not ok 29\n"}

eval {Rmpfr_set_str_binary($f, '-1000.11E-3')};
if($@) {print "ok 30\n"}
else {print "not ok 30\n"}

Rmpfr_set_str($f, '-1000.11E-3', 2, MPFR_RNDN);

$f *= -1;

if($have_mpq) {
  my $q = Math::GMPq::Rmpq_init();
  Math::GMPq::Rmpq_set_ui($q, 11, 17);

  Rmpfr_add_q($f, $f, $q, GMP_RNDN);
  Rmpfr_sub_q($f, $f, $q, GMP_RNDN);

  if($f > 1.0937499 && $f < 1.0937501) {print "ok 31\n"}
  else {print "not ok 31\n"}
}
else {
  warn "Skipping test 31 - no Math::GMPq\n";
  print "ok 31\n";
}

my ($u1, $cmp1) = Rmpfr_init_set_str('1.a', 16, GMP_RNDN);
if(!$cmp1) {print "ok 32\n"}
else {print "not ok 32\n"}

my ($u2, $cmp2) = Rmpfr_init_set_str('1.a', 10, GMP_RNDZ);
if($cmp2 == -1) {print "ok 33\n"}
else {print "not ok 33\n"}

####################################

$ok = '';

#my $h = Rmpfr_init2(59);
#Rmpfr_set_str_binary ($h, "-0.10010001010111000011110010111010111110000000111101100111111E663");
#if (Rmpfr_can_round ($h, 54, GMP_RNDZ, GMP_RNDZ, 53) != 0) {$ok = 'E'}
#else {$ok = 'a'}
#
#Rmpfr_set_str_binary ($h, "-Inf");
#if (Rmpfr_can_round ($h, 2000, GMP_RNDZ, GMP_RNDZ, 2000) != 0) {$ok .= 'E'}
#else {$ok .= 'b'}
#
#Rmpfr_set_prec ($h, 64);
#Rmpfr_set_str_binary ($h, "0.1011001000011110000110000110001111101011000010001110011000000000");
#if (Rmpfr_can_round ($h, 65, GMP_RNDN, GMP_RNDN, 54)) {$ok .= 'E'}
#else {$ok .= 'c'}
#
#if($ok eq 'abc') {print "ok 34\n"}
#else {print "not ok 34 $ok\n"}

print "ok 34\n"; # test removed because Rmpfr_set_str_binary no longer implemented

my $k = Rmpfr_init2(53);
my $str = '1' x 53;
Rmpfr_set_str($k, $str, 2, GMP_RNDN);
my @deref = Math::MPFR::Rmpfr_deref2($k, 10, 0, GMP_RNDN);
if($deref[0] eq '90071992547409910') {print "ok 35\n"}
else {print "not ok 35 $deref[0]\n"}

$ok = '';

if($Config::Config{longsize} == 8) {
  if(Rmpfr_fits_ulong_p($k, GMP_RNDN) && Rmpfr_fits_slong_p($k, GMP_RNDN)) {$ok = 'a'}
}
else {
  if(!Rmpfr_fits_ulong_p($k, GMP_RNDN) && !Rmpfr_fits_slong_p($k, GMP_RNDN)) {$ok = 'a'}
}

Rmpfr_set_d($k, 123.456789, GMP_RNDN);

if(Rmpfr_fits_ulong_p($k, GMP_RNDN) && Rmpfr_fits_slong_p($k, GMP_RNDN)) {$ok .= 'b'}

Rmpfr_set_d($k, 2147483648.4444, GMP_RNDN);

if($Config::Config{longsize} == 8) {
  if(Rmpfr_fits_ulong_p($k, GMP_RNDN) && Rmpfr_fits_slong_p($k, GMP_RNDN)) {$ok .= 'c'}
}
else {
if(Rmpfr_fits_ulong_p($k, GMP_RNDN) && !Rmpfr_fits_slong_p($k, GMP_RNDN)) {$ok .= 'c'}
}

if($ok eq 'abc') {print "ok 36\n"}
else {print "not ok 36 $ok\n"}

if(Rmpfr_get_ui($k, GMP_RNDN) == 2147483648) {print "ok 37\n"}
else {print "not ok 37\n"}

Rmpfr_set_si($k, -2147483647, GMP_RNDN);
if(Rmpfr_get_si($k, GMP_RNDN) == -2147483647) {print "ok 38\n"}
else {print "not ok 38\n"}

my $u = Math::MPFR->new(256);

if(Rmpfr_fits_intmax_p($u, GMP_RNDN) && Rmpfr_fits_sint_p($u, GMP_RNDN) &&
   Rmpfr_fits_slong_p($u, GMP_RNDN) && Rmpfr_fits_sshort_p($u, GMP_RNDN) &&
   Rmpfr_fits_uint_p($u, GMP_RNDN) && Rmpfr_fits_uintmax_p($u, GMP_RNDN) &&
   Rmpfr_fits_ulong_p($u, GMP_RNDN) && Rmpfr_fits_ushort_p($u, GMP_RNDN)) {print "ok 39\n"}
else {print "not ok 39\n"}


Rmpfr_set_default_rounding_mode(GMP_RNDN);

my $double = 17.625;

if($double == Rmpfr_get_NV(Math::MPFR->new($double), GMP_RNDN)) {print "ok 40\n"}
else {
  warn "\nGot: ", Rmpfr_get_NV(Math::MPFR->new($double), GMP_RNDN) , "\nExpected: $double\n";
  print "not ok 40\n";
}

$ok = '';

if(MPFR_VERSION_MAJOR >= 3) {
  if(Rmpfr_regular_p(Math::MPFR->new(17))) {$ok .= 'a'}
  if(!Rmpfr_regular_p(Math::MPFR->new(0))) {$ok .= 'b'}
  if(!Rmpfr_regular_p(Math::MPFR->new())) {$ok .= 'c'}
  if(!Rmpfr_regular_p(Math::MPFR->new(-1) / Math::MPFR->new(0))) {$ok .= 'd'}
  if(!Rmpfr_regular_p(Math::MPFR->new(1) / Math::MPFR->new(0))) {$ok .= 'e'}

  if($ok eq 'abcde') {print "ok 41\n"}
  else {
    warn "41: \$ok: $ok\n";
    print "not ok 41\n";
  }

  Rmpfr_set_zero($fma, -1);
  if($fma == 0) {print "ok 42\n"}
  else {
    warn "42: \$fma: $fma\n";
    print "not ok 42\n";
  }

  my $dig1 = Math::MPFR->new();
  my $dig2 = Math::MPFR->new();
  Rmpfr_digamma($dig1, Math::MPFR->new(2), MPFR_RNDN);
  Rmpfr_digamma($dig2, Math::MPFR->new(3), MPFR_RNDN);
  # Let's check the recurrence relation
  my $diff = $dig2 - ($dig1 + 0.5);
  if($diff < 0.00000000001 && $diff > -0.00000000001) {print "ok 43\n"}
  else {
    warn "43: \$diff: $diff\n";
    print "not ok 43\n";
  }

  my $ai = Math::MPFR->new();
  Rmpfr_ai($ai, 1 / Math::MPFR->new(0), MPFR_RNDN);
  if($ai == 0) {print "ok 44\n"}
  else {
    warn "44: \$ai: $ai\n";
    print "not ok 44\n";
  }

  my $flt = Rmpfr_get_flt(Math::MPFR->new(0.25), MPFR_RNDN);
  if($flt == 0.25) {print "ok 45\n"}
  else {
    warn "45: \$flt: $flt\n";
    print "not ok 45\n";
  }

  Rmpfr_set_flt($ai, 0.25, MPFR_RNDN);
  if($ai == 0.25) {print "ok 46\n"}
  else {
    warn "46: \$ai: $ai\n";
    print "not ok 46\n";
  }
}
else {
  eval{Rmpfr_regular_p(Math::MPFR->new())};
  if($@ =~ /Rmpfr_regular_p not implemented/) {print "ok 41\n"}
  else {
    warn "41: \$\@: $@\n";
    print "not ok 41\n";
  }

  eval{Rmpfr_set_zero($fma, -1);};
  if($@ =~ /Rmpfr_set_zero not implemented/) {print "ok 42\n"}
  else {
    warn "42: \$\@: $@\n";
    print "not ok 42\n";
  }

  eval{Rmpfr_digamma($fma, $fma, MPFR_RNDN);};
  if($@ =~ /Rmpfr_digamma not implemented/) {print "ok 43\n"}
  else {
    warn "43: \$\@: $@\n";
    print "not ok 43\n";
  }

  eval{Rmpfr_ai($fma, $fma, MPFR_RNDN);};
  if($@ =~ /Rmpfr_ai not implemented/) {print "ok 44\n"}
  else {
    warn "44: \$\@: $@\n";
    print "not ok 44\n";
  }

  eval{my $flt = Rmpfr_get_flt($fma, MPFR_RNDN);};
  if($@ =~ /Rmpfr_get_flt not implemented/) {print "ok 45\n"}
  else {
    warn "45: \$\@: $@\n";
    print "not ok 45\n";
  }

  eval{Rmpfr_set_flt($fma, 0.3, MPFR_RNDN);};
  if($@ =~ /Rmpfr_set_flt not implemented/) {print "ok 46\n"}
  else {
    warn "46: \$\@: $@\n";
    print "not ok 46\n";
  }
}

