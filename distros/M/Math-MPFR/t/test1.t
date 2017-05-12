use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;

$| = 1;

print "1..85\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $double = 12345.5;
my $ui = 4;
my $si = -1369012;
my ($ok, $exp);

my($have_mpz, $have_mpf, $have_mpq, $have_Math_GMP) = (0, 0, 0, 0);

eval{require Math::GMPz};
if(!$@) {$have_mpz = 1}

eval{require Math::GMPf};
if(!$@) {$have_mpf = 1}

eval{require Math::GMPq};
if(!$@) {$have_mpq = 1}

eval{require Math::GMP};
if(!$@) {$have_Math_GMP = 1}

my($z, $f, $q, $qq);

if($have_mpz) {$z = Math::GMPz::Rmpz_init_set_str('aaaaaaaaaaaaaaaaaaaa', 36)}
if($have_mpq) {
  $q = Math::GMPq::Rmpq_init();
  Math::GMPq::Rmpq_set_str($q, 'qqqqqqqqqqqqqq/12345z', 36);
  Math::GMPq::Rmpq_canonicalize($q);
  }
if($have_mpf) {$f = Math::GMPf::Rmpf_init_set_str('zzzzzzzzzzzzz123@-5', 36)}

if(Rmpfr_get_default_prec() == 53) {print "ok 1\n"}
else {print "not ok 1\n"}

Rmpfr_set_default_prec(101);
if(Rmpfr_get_default_prec() == 101) {print "ok 2\n"}
else {print "not ok 2\n"}

if(MPFR_VERSION_MAJOR >= 3) {
  if(Rmpfr_min_prec(Math::MPFR->new(0)) == 0) {$ok = 'a'}
  else {warn "3a: ", Rmpfr_min_prec(Math::MPFR->new(0)), "\n"}

  if(Rmpfr_min_prec(Math::MPFR->new(31)) == 5) {$ok .= 'b'}
  else {warn "3b: ", Rmpfr_min_prec(Math::MPFR->new(31)), "\n"}
}
else {
  eval{Rmpfr_min_prec(Math::MPFR->new(0));};
  if($@ =~ /not implemented for/) {$ok = 'a'}
  else {warn "3a: ", $@ ? $@ : "\$\@ unexpectedly not set"}

  eval{Rmpfr_min_prec(Math::MPFR->new(31));};
  if($@ =~ /not implemented for/) {$ok .= 'b'}
  else {warn "3b: ", $@ ? $@ : "\$\@ unexpectedly not set"}
}

if(RMPFR_PREC_MAX > RMPFR_PREC_MIN) {$ok .= 'c'}
else {warn "RMPFR_PREC_MAX: ", RMPFR_PREC_MAX, "\nRMPFR_PREC_MIN: ", RMPFR_PREC_MIN, "\n"}

if($ok eq 'abc') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3\n";
}

$ok = '';

my $c = Rmpfr_init();
my $c_ui = Rmpfr_init();
my $d = Rmpfr_init2(300);
my $e = Rmpfr_init2(300);
my $check = Rmpfr_init2(300);
my $check2 = Rmpfr_init2(300);
my $check3 = Rmpfr_init2(300);
#my $check4 = Rmpfr_init2(300);
my $angle = Rmpfr_init2(300);
my $unity = Rmpfr_init2(300);
my $s = Rmpfr_init2(300);
my $t = Rmpfr_init2(300);
my $log1 = Rmpfr_init2(200);
my $log2 = Rmpfr_init2(150);

Rmpfr_set_d($angle, 3.217, GMP_RNDN);
Rmpfr_set_ui($unity, 1, GMP_RNDN);
#print Rmpfr_get_prec($c), "\n";

if(Rmpfr_get_prec($c) >= 101 && Rmpfr_get_prec($c) < 300 && Rmpfr_get_prec($d) >= 300) {print "ok 4\n"}
else {print "not ok 4\n"}

Rmpfr_set_prec($c, 300);
if(Rmpfr_get_prec($c) == 300) {print "ok 5\n"}
else {print "not ok 5\n"}

Rmpfr_set_str($c, 'afsder.dgk1111111111111111111116', 36, GMP_RNDZ);

my $s3 = Rmpfr_get_str($c, 16, 75, GMP_RNDU);
my $s4 = Rmpfr_get_str($c, 16, 75, GMP_RNDD);

if($s3 ne $s4) {print "ok 6\n"}
else {print "not ok 6 $s3 $s4\n"}

Rmpfr_set($d, $c, GMP_RNDD);

$s3 = Rmpfr_get_str($d, 16, 75, GMP_RNDU);
$s4 = Rmpfr_get_str($d, 16, 75, GMP_RNDD);

if($s3 ne $s4) {print "ok 7\n"}
else {print "not ok 7 $s3 $s4\n"}

Rmpfr_set_d($c, $double, GMP_RNDN);

if(Rmpfr_get_d($c, GMP_RNDN) == $double) {print "ok 8\n"}
else {print "not ok 8\n"}

if(Rmpfr_get_d1($c) == $double) {print "ok 9\n"}
else {print "not ok 9\n"}

if($have_mpz) {
  Rmpfr_set_z($c, $z, GMP_RNDN);
  if(Rmpfr_get_str($c, 36, 20, GMP_RNDN) eq 'a.aaaaaaaaaaaaaaaaaaa@19') {print "ok 10\n"}
  else {print "not ok 10 ", Rmpfr_get_str($c, 36, 20, GMP_RNDN), "\n"}
  }
else {
  warn "Skipping test 10 - no Math::GMPz\n";
  print "ok 10\n";
}

Rmpfr_set_prec($c, 53);

Rmpfr_set_ui($c, 2, GMP_RNDN);

if($have_mpz) {
  my $exp = Rmpfr_get_z_exp($z, $c);
  if($exp == -51 && Math::GMPz::Rmpz_get_str($z, 10) eq '4503599627370496') {print "ok 11\n"}
  else {print "not ok 11\n"}
  }
else {
  warn "Skipping test 11 - no Math::GMPz\n";
  print "ok 11\n";
}

Rmpfr_set_prec($c, 300);
Rmpfr_set_str($c, 'zyxwvp123456@-2', 36, GMP_RNDN);
Rmpfr_set($check, $c, GMP_RNDN);
Rmpfr_add($c, $c, $d, GMP_RNDN);
Rmpfr_add_ui($c, $c, 12345, GMP_RNDN);
Rmpfr_sub($c, $c, $d, GMP_RNDN);
Rmpfr_sub_ui($c, $c, 12345, GMP_RNDN);

if(Rmpfr_eq($c, $check, 250)) {print "ok 12\n"}
else {print "not ok 12\n"}

Rmpfr_ui_sub($check, 0, $c, GMP_RNDN);
Rmpfr_neg($c, $c, GMP_RNDN);

if(!Rmpfr_cmp($c, $check)) {print "ok 13\n"}
else {print "not ok 13\n"}

Rmpfr_add($check, $c, $c,  GMP_RNDN);
Rmpfr_mul_ui($check2, $c, 2, GMP_RNDN);
Rmpfr_mul_2exp($check3, $c, 1, GMP_RNDN);

if(!Rmpfr_cmp($check, $check2) && !Rmpfr_cmp($check, $check3)) {print "ok 14\n"}
else {print "not ok 14\n"}

Rmpfr_div_ui($check2, $check, 2, GMP_RNDN);
Rmpfr_div_2exp($check3, $check, 1, GMP_RNDN);
Rmpfr_mul_2ui($check3, $check3, 3, GMP_RNDN);
Rmpfr_mul_2si($check3, $check3, -3, GMP_RNDN);
Rmpfr_div_2ui($check3, $check3, 3, GMP_RNDN);
Rmpfr_div_2si($check3, $check3, -3, GMP_RNDN);

if(!Rmpfr_cmp($check2, $check3)) {print "ok 15\n"}
else {print "not ok 15\n"}

Rmpfr_div($check, $c, $c, GMP_RNDN);

if(!Rmpfr_cmp_ui($check, 1)) {print "ok 16\n"}
else {print "not ok 16\n"}

Rmpfr_ui_div($check, 1, $c, GMP_RNDN);
Rmpfr_mul($check, $c, $check, GMP_RNDN);

if(!Rmpfr_cmp_ui($check, 1)) {print "ok 17\n"}
else {print "not ok 17\n"}

Rmpfr_pow_ui($check2, $c, 2, GMP_RNDN);
Rmpfr_sqrt($check2, $check2, GMP_RNDN);

if(Rmpfr_cmp($check2, $c) && !Rmpfr_eq($check2, $c, 10)) {print "ok 18\n"}
else {print "not ok 18\n"}

Rmpfr_abs($c, $c, GMP_RNDN);

if(Rmpfr_eq($check2, $c, 280)) {print "ok 19\n"}
else {print "not ok 19\n"}

if(Rmpfr_nan_p($e) && Rmpfr_number_p($c) && Rmpfr_sgn($c) == 1) {print "ok 20\n"}
else {print "not ok 20\n"}

Rmpfr_div_ui($check2, $c, 0, GMP_RNDN);
if(Rmpfr_inf_p($check2)) {print "ok 21\n"}
else {print "not ok 21\n"}

Rmpfr_neg($check2, $c, GMP_RNDN);

Rmpfr_reldiff($check, $check2, $c, GMP_RNDN);

if(!Rmpfr_cmp_si($check, -2)) {print "ok 22\n"}
else {print "not ok 22\n"}

if($have_mpz) {
  Rmpfr_div_z($check2, $c, $z, GMP_RNDN);
  Rmpfr_mul_z($check2, $check2, $z, GMP_RNDN);
  if(Rmpfr_eq($check2, $c, 280)) {print "ok 23\n"}
  else {print "not ok 23\n"}
  }
else {
  warn "Skipping test 23 - no Math::GMPz\n";
  print "ok 23\n";
}

if($have_mpq) {
  Rmpfr_div_q($check2, $c, $q, GMP_RNDN);
  Rmpfr_mul_q($check2, $check2, $q, GMP_RNDN);
  if(Rmpfr_eq($check2, $c, 280)) {print "ok 24\n"}
  else {print "not ok 24\n"}
  }
else {
  warn "Skipping test 24 - no Math::GMPq\n";
  print "ok 24\n";
}

Rmpfr_neg($check, $c, GMP_RNDN);
Rmpfr_set($check2, $c, GMP_RNDN);
Rmpfr_swap($check2, $check);
Rmpfr_add($check3, $check2, $check, GMP_RNDN);

if(Rmpfr_sgn($check2) == -1 && Rmpfr_sgn($check) == 1 && !Rmpfr_cmp_ui($check3, 0)) {print "ok 25\n"}
else {print "not ok 25\n"}

Rmpfr_sin_cos($s, $c, $angle, GMP_RNDN);
Rmpfr_pow_ui($check, $s, 2, GMP_RNDN);
Rmpfr_pow_ui($check2, $c, 2, GMP_RNDN);
Rmpfr_add($check3, $check2, $check, GMP_RNDN);

if(Rmpfr_eq($check3, $unity, 280)) {print "ok 26\n"}
else {print "not ok 26\n"}

Rmpfr_tan($t, $angle, GMP_RNDN);
Rmpfr_div($check, $s, $c, GMP_RNDN);

if(Rmpfr_eq($t, $check, 280)) {print "ok 27\n"}
else {print "not ok 27\n"}

my $d2;

  Rmpfr_const_pi($c, GMP_RNDN);
  $d2 = Rmpfr_get_d($c, GMP_RNDN);

  if($d2 > 3.14159265 && $d2 < 3.14159266) {print "ok 28\n"}
  else {print "not ok 28\n"}

Rmpfr_const_euler($c, GMP_RNDN);
$d2 = Rmpfr_get_d($c, GMP_RNDN);

if($d2 > 0.5772156649 && $d2 < 0.577215665) {print "ok 29\n"}
else {print "not ok 29\n"}

Rmpfr_const_log2($c, GMP_RNDN);
$d2 = Rmpfr_get_d($c, GMP_RNDN);

if($d2 > 0.69314718 && $d2 < 0.69314719) {print "ok 30\n"}
else {print "not ok 30\n"}

my $ret = Rmpfr_exp($c, $unity, GMP_RNDN);
$d2 = Rmpfr_get_d($c, GMP_RNDN);

if($ret && $d2 > 2.7182818284 && $d2 < 2.7182818285) {print "ok 31\n"}
else {print "not ok 31\n"}

Rmpfr_set_d($c, $d2, GMP_RNDN);
Rmpfr_log($c, $c, GMP_RNDN);
$d2 = Rmpfr_get_d($c, GMP_RNDN);

if($d2 > 0.99999 && $d2 < 1.00001) {print "ok 32\n"}
else {print "not ok 32\n"}

Rmpfr_set_d($c, $double, GMP_RNDN);
Rmpfr_exp2($c, $c, GMP_RNDN);
Rmpfr_log2($c, $c, GMP_RNDN);
$d2 = Rmpfr_get_d($c, GMP_RNDN);
if($d2 > 12345.49 && $d2 < 12345.51) {print "ok 33\n"}
else {print "not ok 33\n"}

Rmpfr_set_d($c, 3.6, GMP_RNDN);
Rmpfr_exp10($c, $c, GMP_RNDN);
Rmpfr_log10($c, $c, GMP_RNDN);
$d2 = Rmpfr_get_d($c, GMP_RNDN);
if($d2 > 3.59 && $d2 < 3.61) {print "ok 34\n"}
else {print "not ok 34\n"}

Rmpfr_set_d($c, $double, GMP_RNDN);
Rmpfr_set_ui($d, 10, GMP_RNDN);
Rmpfr_pow($c, $d, $c, GMP_RNDN);

Rmpfr_log10($c, $c, GMP_RNDN);
$d2 = Rmpfr_get_d($c, GMP_RNDN);

if($d2 > 12345.49 && $d2 < 12345.51) {print "ok 35\n"}
else {print "not ok 35\n"}

Rmpfr_set_ui($check2, 12345, GMP_RNDN);
Rmpfr_set_ui($check3, 12346, GMP_RNDN);
Rmpfr_agm($check, $check3, $check2, GMP_RNDN);
$d2 = Rmpfr_get_d($check, GMP_RNDN);

if($d2 > 12345.49999 && $d2 < 12345.50001) {print "ok 36\n"}
else {print "not ok 36\n"}

$ret = '';

Rmpfr_set_d($d, 123456.6, GMP_RNDN);
Rmpfr_rint($c, $d, GMP_RNDD);
if(!Rmpfr_cmp_ui($c, 123456)) { $ret .= 'a'}

Rmpfr_ceil($c, $d);
if(!Rmpfr_cmp_ui($c, 123457)) { $ret .= 'b'}

Rmpfr_floor($c, $d);
if(!Rmpfr_cmp_ui($c, 123456)) { $ret .= 'c'}

Rmpfr_round($c, $d);
if(!Rmpfr_cmp_ui($c, 123457)) { $ret .= 'd'}

Rmpfr_trunc($c, $d);
if(!Rmpfr_cmp_ui($c, 123456)) { $ret .= 'e'}

if($ret eq 'abcde') {print "ok 37\n"}
else {print "not ok 37 $ret\n"}

if(Rmpfr_get_emin() < -1000000 && Rmpfr_get_emax > 1000000) {print "ok 38\n"}
else {print "not ok 38\n"}

if(!Rmpfr_check_range($d, 0, GMP_RNDN)) {print "ok 39\n"}
else {print "not ok 39\n"}

if($have_mpf) {
  Rmpfr_set_f($c, $f, GMP_RNDN);
  Rmpfr_set_str($d, 'zzzzzzzzzzzzz123@-5', 36, GMP_RNDN);
  if(Rmpfr_eq($c, $d, 100)) {print "ok 40\n"}
  else {print "not ok 40\n"}
  }
else {
  warn "Skipping test 40 - no Math::GMPf\n";
  print "ok 40\n";
}

my @r = ();
Rmpfr_set_default_prec(75);
for(1..100) {push @r, Rmpfr_init()}

if($have_mpz) {
  my $str = '1';

  for(1..63) {$str .= int(rand(2))}

  my $seed = Math::GMPz::Rmpz_init_set_str($str, 2);
  my $state = Rmpfr_randinit_default();

  Rmpfr_randseed($state, $seed);

  $ok = 1;

  Rmpfr_urandomb(@r, $state);

  for(@r) {
     if(length(Rmpfr_get_str($_, 2, 0, GMP_RNDN)) > 80 || length(Rmpfr_get_str($_, 2, 0, GMP_RNDN)) < 40) {$ok = 0}
     if($_ <= 0 || $_ >= 1) {$ok = 0}
     }

  for(my $i = 0; $i < 100; $i++) {
     for(my $j = $i + 1; $j < 100; $j++) {
        if($r[$i] == $r[$j]) {$ok = 0}
        }
     }

  if($ok) {print "ok 41\n"}
  else {print "not ok 41\n"}

  Rmpfr_randclear($state);
  }
else {
  warn "Skipping test 41 - no Math::GMPz\n";
  print "ok 41\n";
}

{
  my $str = '';

  for(1..21) {$str .= 1 + int(rand(9))}

  my $state = Rmpfr_randinit_lc_2exp_size(100);

  Rmpfr_randseed($state, $str);

  my $ok = 1;

  Rmpfr_urandomb(@r, $state);

  for(@r) {
     if(length(Rmpfr_get_str($_, 2, 0, GMP_RNDN)) > 80 || length(Rmpfr_get_str($_, 2, 0, GMP_RNDN)) < 40) {$ok = 0}
     if($_ <= 0 || $_ >= 1) {$ok = 0}
     }

  for(my $i = 0; $i < 100; $i++) {
     for(my $j = $i + 1; $j < 100; $j++) {
        if($r[$i] == $r[$j]) {$ok = 0}
        }
     }

  if($ok) {print "ok 42\n"}
  else {print "not ok 42\n"}

  Rmpfr_randclear($state);
}

my $o = Rmpfr_init();
Rmpfr_set_d($o, $double, GMP_RNDN);

my ($t1, $s1) = Rmpfr_init_set($o, GMP_RNDN);
my ($t2, $s2) = Rmpfr_init_set_d($double, GMP_RNDN);

if(Rmpfr_eq($t1, $t2, 50)) {print "ok 43\n"}
else {print "not ok 43\n"}

my ($t3, $s33) = Rmpfr_init_set_ui(int($double), GMP_RNDN);
my ($t4, $s44) = Rmpfr_init_set_si(int($double) + 1, GMP_RNDN);

if(Rmpfr_cmp($t3, $t2) < 0
  && Rmpfr_cmp($t4, $t2) > 0
  && Rmpfr_get_prec($t3) == Rmpfr_get_default_prec()) {print "ok 44\n"}
else {print "not ok 44\n"}

if($have_mpz) {
   eval {my $t = Rmpfr_init_set_z($z, GMP_RNDN)};
   if(!$@) {print "ok 45\n"}
   else {print "not ok 45\n"}
   }
else {
  warn "Skipping test 45 - no Math::GMPz\n";
  print "ok 45\n";
}

if($have_mpq) {
   eval {my $t = Rmpfr_init_set_q($q, GMP_RNDN)};
   if(!$@) {print "ok 46\n"}
   else {print "not ok 46\n"}
   }
else {
  warn "Skipping test 46 - no Math::GMPq\n";
  print "ok 46\n";
}

if($have_mpf) {
   eval {my $t = Rmpfr_init_set_f($f, GMP_RNDN)};
   if(!$@) {print "ok 47\n"}
   else {print "not ok 47\n"}
   }
else {
  warn "Skipping test 47 - no Math::GMPf\n";
  print "ok 47\n";
}

if($have_mpz) {
   # Check that a specific MPFR bug has been fixed

   Rmpfr_clear_nanflag();

   Math::GMPz::Rmpz_set_ui($z, 0);
   Rmpfr_set($check, $c, GMP_RNDN);

   my $ok = '';

   Rmpfr_add_z($c, $c, $z, GMP_RNDN);
   if($c == $check) {$ok = 'a'}

   Rmpfr_sub_z($c, $c, $z, GMP_RNDN);
   if($c == $check) {$ok .= 'b'}

   Rmpfr_mul_z($check, $c, $z, GMP_RNDN);
   if($check == 0) {$ok .= 'c'}

   my $flag = Rmpfr_nanflag_p();

   Rmpfr_div_z($check, $c, $z, GMP_RNDN);
   if(Rmpfr_inf_p($check)) {$ok .= 'd'}

   if($ok eq 'abcd' && !$flag
     && Math::MPFR::get_refcnt($c) == 1
     && Math::MPFR::get_refcnt($check) == 1){print "ok 48\n"}
   else {print "not ok 48 \$ok: $ok   \$flag: $flag\n"}
   }
else {
  warn "Skipping test 48 - no Math::GMPz\n";
  print "ok 48\n";
}

$ok = '';

$check = $c;
$c *= 0;

if($check != $c) {$ok = 'a'}
$check *= 0;

if($check == $c) {$ok .= 'b'}

Rmpfr_clear_nanflag();
my $flag = Rmpfr_nanflag_p();

$check = $check / $c;
if(!$flag && Rmpfr_nanflag_p()
   && Math::MPFR::get_refcnt($check) == 1
   && Math::MPFR::get_refcnt($c) == 1
   && $ok eq 'ab') {print "ok 49\n"}
else {print "not ok 49 (Got: $flag ", Rmpfr_nanflag_p(), " $ok)\n"}

########################



###############################################

my $inf = Rmpfr_init();
Rmpfr_set_inf($inf, -1);

if(Rmpfr_inf_p($inf)) {print "ok 50\n"}
else {print "not ok 50\n"}

my $nan = Rmpfr_init();
Rmpfr_set_nan($nan);

if(Rmpfr_nan_p($nan)) {print "ok 51\n"}
else {print "not ok 51\n"}

Rmpfr_set_si($inf, -27, GMP_RNDN);
Rmpfr_cbrt($inf, $inf, GMP_RNDN);

if($inf == -3 && Rmpfr_integer_p($inf)) {print "ok 52\n"}
else {print "not ok 52\n"}

$ok = 1;
my @r3 = ();
Rmpfr_set_default_prec(75);
for(1..100) {push @r3, Rmpfr_init()}

if(!(MPFR_VERSION_MAJOR > 2)) {

  for(@r3) {Rmpfr_random2($_, 6, 2)}

  my $dup_count = 0;

  for(my $i = 0; $i < 100; $i++) {
     for(my $j = $i + 1; $j < 100; $j++) {
        if($r3[$i] == $r3[$j]) {$dup_count ++}
        }
     }

  if($dup_count < 6) {print "ok 53\n"}
  else {print "not ok 53\n"}
}
else {
  warn "Skipping test 53: Rmpfr_random2 no longer implemented\n";
  print "ok 53\n";
}

Rmpfr_set_si($c, -123, GMP_RNDN);
Rmpfr_set_si($check, -7, GMP_RNDN);

if(Rmpfr_cmpabs($c, $check) > 0 && !Rmpfr_unordered_p($c, $check)) {print "ok 54\n"}
else {print "not ok 54\n"}

$ok = '';

Rmpfr_min($check2, $check, $c, GMP_RNDN);
if($check2 == $c) {$ok = 'a'}

Rmpfr_max($check2, $check, $c, GMP_RNDN);
if($check2 == $check) {$ok .= 'b'}

if($ok eq 'ab') {print "ok 55\n"}
else {print "not ok 55 $ok\n"}

my $log3 = Rmpfr_init2(200);
my $signp;

Rmpfr_set_d($c, 1.003, GMP_RNDN);
Rmpfr_lngamma($log2, $c, GMP_RNDN);
($signp, $ret) = Rmpfr_lgamma($log3, $c, GMP_RNDN);
Rmpfr_gamma($c, $c, GMP_RNDN);
Rmpfr_log($log1, $c, GMP_RNDN);

if($c > 0.9982772 && $c < 0.9982773){print "ok 56\n"}
else {print "not ok 56\n"}

$ok = '';

if($log1 - $log3 < 0.000000001 &&
   $log1 - $log3> -0.000000001){$ok .= 'a'}

if($signp == 1) {$ok .= 'b'}

if($log1 - $log2 < 0.000000001 &&
   $log1 - $log2 > -0.000000001){$ok .= 'c'}

if($ok eq 'abc'){print "ok 57\n"}
else {print "not ok 57 $ok\n"}

Rmpfr_set_ui($c, 0, GMP_RNDN);
Rmpfr_erf($check, $c, GMP_RNDN);

if($check == 0) {print "ok 58\n"}
else {print "not ok 58\n"}

Rmpfr_const_pi($check, GMP_RNDN);
$check **= 4;
$check /= 90;

Rmpfr_set_ui($c, 4, GMP_RNDN);
Rmpfr_zeta($c, $c, GMP_RNDN);
Rmpfr_zeta_ui($c_ui, 4, GMP_RNDN);

$ok = '';

if($c > $check - 0.00001 && $c < $check + 0.00001) {$ok .= 'a'}
else {warn "59 a: $c\n$check\n"}

if($c_ui > $check - 0.00001 && $c_ui < $check + 0.00001) {$ok .= 'b'}
else {warn "59 b: $c_ui\n$check\n"}

if($ok eq 'ab') {print "ok 59\n"}
else {print "not ok 59 $ok\n"}

my $fail = Rmpfr_set_exp($c, -5);

if(!$fail && Rmpfr_get_exp($c) == -5) {print "ok 60\n"}
else {print "not ok 60\n"}

if(1) {
  my $str = '';

  for(1..21) {$str .= 1 + int(rand(10))}

  my $state = Rmpfr_randinit_lc_2exp_size(90);

  Rmpfr_randseed($state, $str);

  my $ok = 1;

  Rmpfr_urandomb(@r, $state);

  for(@r) {
     if(length(Rmpfr_get_str($_, 2, 0, GMP_RNDN)) > 80 || length(Rmpfr_get_str($_, 2, 0, GMP_RNDN)) < 40) {$ok = 0}
     if($_ <= 0 || $_ >= 1) {$ok = 0}
     }

  for(my $i = 0; $i < 100; $i++) {
     for(my $j = $i + 1; $j < 100; $j++) {
        if($r[$i] == $r[$j]) {$ok = 0}
        }
     }

  if($ok) {print "ok 61\n"}
  else {print "not ok 61\n"}

  Rmpfr_randclear($state);
  }

##########################################

if($have_mpz) {
  my $str = '';

  for(1..21) {$str .= 1 + int(rand(9))}

  my $seed = Math::GMPz::Rmpz_init_set_str($str, 10);

  my $state = Rmpfr_randinit_lc_2exp_size(120);

  Rmpfr_randseed($state, $seed);

  my $ok = 1;

  Rmpfr_urandomb(@r, $state);

  for(@r) {
     if(length(Rmpfr_get_str($_, 2, 0, GMP_RNDN)) > 80 || length(Rmpfr_get_str($_, 2, 0, GMP_RNDN)) < 40) {$ok = 0}
     if($_ <= 0 || $_ >= 1) {$ok = 0}
     }

  for(my $i = 0; $i < 100; $i++) {
     for(my $j = $i + 1; $j < 100; $j++) {
        if($r[$i] == $r[$j]) {$ok = 0}
        }
     }

  if($ok) {print "ok 62\n"}
  else {print "not ok 62\n"}

  Rmpfr_randclear($state);
  }
else {
  warn "Skipping test 62 - no Math::GMPz\n";
  print "ok 62\n";
}

#########################
if(1) {
  my $str = '';

  for(1..21) {$str .= 1 + int(rand(10))}

  my $state = Rmpfr_randinit_lc_2exp_size(100);

  Rmpfr_randseed_ui($state, 1123456);

  my $ok = 1;

  Rmpfr_urandomb(@r, $state);

  for(@r) {
     if(length(Rmpfr_get_str($_, 2, 0, GMP_RNDN)) > 80 || length(Rmpfr_get_str($_, 2, 0, GMP_RNDN)) < 40) {$ok = 0}
     if($_ <= 0 || $_ >= 1) {$ok = 0}
     }

  for(my $i = 0; $i < 100; $i++) {
     for(my $j = $i + 1; $j < 100; $j++) {
        if($r[$i] == $r[$j]) {$ok = 0}
        }
     }

  if($ok) {print "ok 63\n"}
  else {print "not ok 63\n"}

  Rmpfr_randclear($state);
  }

Rmpfr_set_d($c, 1123.5, GMP_RNDN);
eval {Rmpfr_out_str($c, 10, 0, GMP_RNDN);
      print "\n";};

if($@) {print "not ok 64\n"}
else {print "ok 64\n"}

eval {Rmpfr_print_binary($c);
      print "\n";};

if($@) {print "ok 65\n"}
else {print "not ok 65\n"}

eval {Rmpfr_dump($c);};

if($@) {print "not ok 66\n"}
else {print "ok 66\n"}

eval{$ok = Math::MPFR::gmp_v();};

if($@ || $ok =~ /[^0-9\.]/) {print "not ok 67\n"}
else {print "ok 67\n"}

Rmpfr_const_catalan($c, GMP_RNDN);

if($c - 0.915965594177 < 0.0000000001 &&
   $c - 0.915965594177 > - 0.0000000001) {print "ok 68\n"}
else {print "not ok 68\n"}

Rmpfr_set_si($c, -3, GMP_RNDN);
Rmpfr_lngamma($c, $c, GMP_RNDN);

if(Rmpfr_inf_p($c)) {print "ok 69\n"}
else {
  warn "lngamma(-3): $c\n";
  print "not ok 69\n";
}

Rmpfr_erf($s, $log1, GMP_RNDN);
Rmpfr_erfc($t, $log1, GMP_RNDN);

# erfc(x) = 1 - erf(x)
if($s + $t < 1.00000000001 &&
   $s + $t > 0.99999999999) {print "ok 70\n"}
else {print "not ok 70\n"}

Rmpfr_set_d($s, 175.92186044416, GMP_RNDN);
Rmpfr_root($s, $s, 11, GMP_RNDN);

if($s - 1.6 < 0.0000000001 &&
   $s - 1.6 > -0.0000000001) {print "ok 71\n"}
else {print "not ok 71\n"}

Rmpfr_set_si($s, -2, GMP_RNDN);
Rmpfr_eint($s, $s, GMP_RNDN);

# The behaviour of mpfr_eint() wrt -ve inputs changes after mpfr-3.1.x
if(MPFR_VERSION >= 197120) {
  if($s < -0.0489005107 && $s > -0.04890051071) {print "ok 72\n"}
  else {
    warn "\n72: got $s\n";
    print "not ok 72\n";
  }
}
elsif(Rmpfr_nan_p($s)) {print "ok 72\n"}
else {print "not ok 72\n"}

Rmpfr_set_default_prec(300);

if($have_mpz) {
   my $zzz = Math::GMPz::Rmpz_init_set_ui(60);
   Rmpfr_set_ui($s, 3, GMP_RNDN);
   Rmpfr_pow_z($s, $s, $zzz, GMP_RNDN);

   if($s == '42391158275216203514294433201') {print "ok 73\n"}
   else {print "not ok 73\n"}
   }
else {
  warn "Skipping test 73 - no Math::GMPz\n";
  print "ok 73\n";
}

if($have_Math_GMP) {
   my $zzz = Math::GMP->new(60);
   Rmpfr_set_ui($s, 3, GMP_RNDN);
   Rmpfr_pow_z($s, $s, $zzz, GMP_RNDN);

   if($s == '42391158275216203514294433201') {print "ok 74\n"}
   else {print "not ok 74\n"}
   }
else {
  warn "Skipping test 74 - no Math::GMP\n";
  print "ok 74\n";
}


if($have_mpf) {
   my $f1 = Math::GMPf::Rmpf_init();
   Rmpfr_set_d($s, 23.625, GMP_RNDN);
   Rmpfr_get_f($f1, $s, GMP_RNDN);

   if(Rmpfr_cmp_f($s, $f1)) {print "not ok 75\n"}
   else {print "ok 75\n"}
   }
else {
  warn "Skipping test 75 - no Math::GMPf\n";
  print "ok 75\n";
}

Rmpfr_set_d($s, 12345.5, GMP_RNDN);
if(Rmpfr_cmp_d($s, 12345.5)) {print "not ok 76\n"}
else {print "ok 76\n"}

if($s ==  12345.5 &&
   $s <=  12345.5 &&
   $s >=  12345.5 &&
   ($s <=> 12345.6) < 0  &&
   ($s <=> 12345.5) == 0 &&
   ($s <=> 12345.4) > 0  &&
   $s !=  12345.4 &&
   $s >   12345.4 &&
   $s >=  12345.4 &&
   $s <   12345.6 &&
   $s <=  12345.6) {print "ok 77\n"}
else {print "not ok 77\n"}

my $hypot1 = Math::MPFR->new(5);
my $hypot2 = Math::MPFR->new(12);

Rmpfr_hypot($s, $hypot1, $hypot2, GMP_RNDN);

if($s == 13) {print "ok 78\n"}
else {print "not ok 78\n"}

my $num1 = Math::MPFR->new(100);

$double = Rmpfr_get_d_2exp($exp, $num1, GMP_RNDN);
if($double > 0.781249 && $double < 0.781251 && $exp == 7) {print "ok 79\n"}
else {
   warn "\n   Got (double): $double\n   Expected: 0.78125\n\n",
        "   Got (exp): $exp\n   Expected: 7\n";
   print "not ok 79\n";
}

my $posinf = Math::MPFR->new('inf');
my $neginf = Math::MPFR->new('-inf');

$ok = '';

if($posinf == - $neginf) {$ok .= 'a'}
else {warn "a: $posinf ", $neginf * -1, "\n"}

$double = Rmpfr_get_d($nan, GMP_RNDN);
Rmpfr_set_d($nan, $double, GMP_RNDN);
if(Rmpfr_nan_p($nan)) {$ok .= 'b'}
else {warn "b: $nan\n"}

$double = Rmpfr_get_d($posinf, GMP_RNDN);
Rmpfr_set_d($posinf, $double, GMP_RNDN);
if(Rmpfr_inf_p($posinf) && $posinf > 0) {$ok .= 'c'}
else {warn "c: $posinf\n"}

$double = Rmpfr_get_d($neginf, GMP_RNDN);
Rmpfr_set_d($neginf, $double, GMP_RNDN);
if(Rmpfr_inf_p($neginf) && $neginf < 0) {$ok .= 'd'}
else {warn "d: $neginf\n"}

$double = Rmpfr_get_NV($nan, GMP_RNDN);
Rmpfr_set_d($nan, $double, GMP_RNDN);
if(Rmpfr_nan_p($nan)) {$ok .= 'e'}
else {warn "e: $nan\n"}

$double = Rmpfr_get_NV($posinf, GMP_RNDN);
Rmpfr_set_d($posinf, $double, GMP_RNDN);
if(Rmpfr_inf_p($posinf) && $posinf > 0) {$ok .= 'f'}
else {warn "f: $posinf\n"}

$double = Rmpfr_get_NV($neginf, GMP_RNDN);
Rmpfr_set_d($neginf, $double, GMP_RNDN);
if(Rmpfr_inf_p($neginf) && $neginf < 0) {$ok .= 'g'}
else {warn "g: $neginf\n"}

if($ok eq 'abcdefg') {print "ok 80\n"}
else {print "not ok 80 $ok\n"}

$ok = '';

my $ac1 = Math::MPFR->new(12.25);
Rmpfr_add_d($ac1, $ac1, 0.25, GMP_RNDN);
if($ac1 == 12.50){$ok .= 'a'}
else {warn "81 a: $ac1\n"}

Rmpfr_sub_d($ac1, $ac1, 0.25, GMP_RNDN);
if($ac1 == 12.25){$ok .= 'b'}
else {warn "81 b: $ac1\n"}

Rmpfr_d_sub($ac1, 24.5, $ac1, GMP_RNDN);
if($ac1 == 12.25){$ok .= 'c'}
else {warn "81 c: $ac1\n"}

Rmpfr_mul_d($ac1, $ac1, 2.5, GMP_RNDN);
if($ac1 == 30.625){$ok .= 'd'}
else {warn "81 d: $ac1\n"}

Rmpfr_div_d($ac1, $ac1, 2.5, GMP_RNDN);
if($ac1 == 12.25){$ok .= 'e'}
else {warn "81 e: $ac1\n"}

Rmpfr_d_div($ac1, 24.5, $ac1, GMP_RNDN);
if($ac1 == 2){$ok .= 'f'}
else {warn "81 f: $ac1\n"}

Rmpfr_set_d($ac1, 0.0625, GMP_RNDN);
Rmpfr_rec_sqrt($ac1, $ac1, GMP_RNDN);
if($ac1 == 4){$ok .= 'g'}
else {warn "81 g: $ac1\n"}

Rmpfr_set_ui($ac1, 0, GMP_RNDN);
Rmpfr_rec_sqrt($ac1, $ac1, GMP_RNDN);
if(Rmpfr_inf_p($ac1)){$ok .= 'h'}
else {warn "81 h: $ac1\n"}

Rmpfr_set_ui($ac1, 0, GMP_RNDN);
Rmpfr_mul_d($ac1, $ac1, -1.0, GMP_RNDN);
Rmpfr_rec_sqrt($ac1, $ac1, GMP_RNDN);
if(Rmpfr_inf_p($ac1)){$ok .= 'i'}
else {warn "81 i: $ac1\n"}

my $ac2 = $ac1;
$ac2 *= -1;

Rmpfr_rec_sqrt($ac1, $ac1, GMP_RNDN);
if($ac1 == 0){$ok .= 'j'}
else {warn "81 j: $ac1\n"}

Rmpfr_rec_sqrt($ac2, $ac2, GMP_RNDN);
if(Rmpfr_nan_p($ac2)){$ok .= 'k'}
else {warn "81 k: $ac2\n"}

Rmpfr_set_d($ac1, 12.25, GMP_RNDN);
Rmpfr_modf($ac1, $ac2, $ac1, GMP_RNDN);

if($ac1 == 12) {$ok .= 'l'}
else {warn "81 l: $ac1\n"}

if($ac2 == 0.25) {$ok .= 'm'}
else {warn "81 m: $ac2\n"}

Rmpfr_set_ui($ac1, 0, GMP_RNDN);
Rmpfr_li2($ac2, $ac1, GMP_RNDN);
if(!$ac2) {$ok .= 'n'}
else {warn "81 n: $ac2\n"}

Rmpfr_set_ui($ac1, 1, GMP_RNDN);
Rmpfr_li2($ac2, $ac1, GMP_RNDN);
if($ac2 > 1.64493406 && $ac2 < 1.64493407) {$ok .= 'o'}
else {warn "81 o: $ac2\n"}

Rmpfr_set_ui($ac1, 2, GMP_RNDN);
Rmpfr_li2($ac2, $ac1, GMP_RNDN);
if($ac2 > 2.4674011002 && $ac2 < 2.4674011003) {$ok .= 'p'}
else {warn "81 p: $ac2\n"}

if($ok eq 'abcdefghijklmnop'){print "ok 81\n"}
else {print "not ok 81 $ok\n"}

if(MPFR_VERSION_MAJOR >= 3) {
  my $str = '';
  for(1..21) {$str .= 1 + int(rand(10))}
  my $state = Rmpfr_randinit_lc_2exp_size(90);
  Rmpfr_randseed($state, $str);
  my $rand = Math::MPFR->new();
  Rmpfr_urandom($rand, $state, MPFR_RNDN);
  if($rand < 1 && $rand > 0) {print "ok 82\n"}
  else {
    warn "82: \$rand: $rand\n";
    print "not ok 82\n";
  }
}
else {
  my $str = '';
  for(1..21) {$str .= 1 + int(rand(10))}
  my $state = Rmpfr_randinit_lc_2exp_size(90);
  Rmpfr_randseed($state, $str);
  my $rand = Math::MPFR->new();
  eval{Rmpfr_urandom($rand, $state, MPFR_RNDN);};
  if($@ =~ /Rmpfr_urandom not implemented/) {print "ok 82\n"}
  else {
    warn "82: \$\@: $@\n";
    print "not ok 82\n";
  }
}

if($have_mpz) {
  my $z = Math::GMPz->new(5);
  my $fr = Math::MPFR->new();
  if(MPFR_VERSION_MAJOR >= 3) {
    Rmpfr_set_z_2exp($fr, $z, -2, MPFR_RNDN);
    if($fr == 1.25) {print "ok 83\n"}
    else {
      warn "83: \$fr: $fr\n";
      print "not ok 83\n";
    }
  }
  else {
    eval{Rmpfr_set_z_2exp($fr, $z, -2, MPFR_RNDN);};
    if($@ =~ /Rmpfr_set_z_2exp not implemented/) {print "ok 83\n"}
    else {
      warn "83: \$\@: $@\n";
      print "not ok 83\n";
    }
  }
}
else {
  warn "Skipping test 83: No Math::GMPz\n";
  print "ok 83\n";
}

if($have_Math_GMP) {
  my $z = Math::GMP->new(5);
  my $fr = Math::MPFR->new();
  if(MPFR_VERSION_MAJOR >= 3) {
    Rmpfr_set_z_2exp($fr, $z, -2, MPFR_RNDN);
    if($fr == 1.25) {print "ok 84\n"}
    else {
      warn "84: \$fr: $fr\n";
      print "not ok 84\n";
    }
  }
  else {
    eval{Rmpfr_set_z_2exp($fr, $z, -2, MPFR_RNDN);};
    if($@ =~ /Rmpfr_set_z_2exp not implemented/) {print "ok 84\n"}
    else {
      warn "84: \$\@: $@\n";
      print "not ok 84\n";
    }
  }
}
else {
  warn "Skipping test 84: No Math::GMP\n";
  print "ok 84\n";
}

my $nnum_val = Math::MPFR::nnumflag();

my $nnum_test = Math::MPFR->new('2 .3');

if(Math::MPFR::nnumflag() == $nnum_val + 1) {print "ok 85\n"}
else {
  warn "\nnnumflag: expected ", $nnum_val + 1, ", got ", Math::MPFR::nnumflag(), "\n";
  print "not ok 85\n";
}

# Run the following to test Rmpfr_inp_str
# and Rmpfr_dump
__END__
print "\nEnter a number [eg .11235\@4]\n";
Rmpfr_inp_str($check, 10, GMP_RNDN);
print "\n";
Rmpfr_dump($check);
print "\n";

