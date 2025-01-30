use Math::GMPf qw(:mpf);
use warnings;
use strict;

print "1..49\n";

print "# Using gmp version ", Math::GMPf::gmp_v(), "\n";

my @version = split /\./, Math::GMPf::gmp_v();
my $old = 0;
if($version[0] == 4 && $version[1] < 2) {$old = 1}
if($old) {warn "Test 47 should fail - GMP version ", Math::GMPf::gmp_v(), " is old and doesn't support base 62\n";}

my $have_mpz = 0;
my $have_mpq = 0;

eval {require Math::GMPz};
if(!$@) {$have_mpz = 1}

eval {require Math::GMPq};
if(!$@) {$have_mpq = 1}

my $double = 123456.01234544541;
my $ui = 123456789;
my $si = -123456788;
my $dp;

# Allow "." or "," as the decimal point (according to whichever is valid for the locale).
eval{Rmpf_init_set_str('21.135@12', 10);};
$dp = '.' unless $@;
eval{Rmpf_init_set_str('21,135@12', 10);};
$dp = ',' unless $@;

my $str = $dp ? "21${dp}135\@12"
             : '21135@9';

#warn "\$str: $str\n";
#warn "Decimal point: $dp\n";

my $p = Rmpf_init2(200);
my $q = Rmpf_init2(Rmpf_get_default_prec);
my $s = Rmpf_init();
my $t = Rmpf_init();
my $z;
my $rat;
if($have_mpz) {$z = Math::GMPz::Rmpz_init_set_str('asdfgkjqqqqqqqqqqq', 36)}
my $r = Rmpf_init_set_str('faaaaaaaaassssssssssssssaaaaaaaaaaaaaah@20', 36);

if($have_mpq) {
  $rat = Math::GMPq::Rmpq_init();
  Math::GMPq::Rmpq_set_ui($rat, 123, 1);
  }


Rmpf_set_default_prec(100);

if(Rmpf_get_default_prec() >= 100) {print "ok 1\n"}
else {print "not ok 1\n"}

if(Rmpf_get_prec($p) >= 200) {print "ok 2\n"}
else {print "not ok 2\n"}

Rmpf_set_prec($p, 300);

if(Rmpf_get_prec($p) >= 300) {print "ok 3\n"}
else {print "not ok 3\n"}

my $prec = Rmpf_get_prec($p);

Rmpf_set_prec_raw($p, $prec + 10);

if(Rmpf_get_prec($p) >= $prec + 10) {print "ok 4\n"}
else {print "not ok 4\n"}

Rmpf_set_prec($p, $prec);

if(Rmpf_get_prec($p) == $prec) {print "ok 5\n"}
else {print "not ok 5\n"}

Rmpf_set_d($p, $double);
Rmpf_set_d($q, $double);

if(!Rmpf_cmp($p, $q)) {print "ok 6\n"}
else {print "not ok 6\n"}

if(!Rmpf_cmp_d($p, $double)) {print "ok 7\n"}
else {print "not ok 7\n"}

Rmpf_set_ui($p, $ui);
if(!Rmpf_cmp_ui($p, $ui)) {print "ok 8\n"}
else {print "not ok 8\n"}

Rmpf_set_si($p, $si);
if(!Rmpf_cmp_si($p, $si)) {print "ok 9\n"}
else {print "not ok 9\n"}

Rmpf_set_str($p, $str, 10);

if(Rmpf_get_str($p, 10, 0) eq '0.21135e14') {print "ok 10\n"}
else {
  warn "10: ", Rmpf_get_str($p, 10, 0), "\n";
  print "not ok 10\n";
}

if($have_mpz) {
  Rmpf_set_z($p, $z);
  if(Rmpf_get_str($p, 36, 0) eq'0.asdfgkjqqqqqqqqqqq@18') {print "ok 11\n"}
  else {print "not ok 11\n"}
}
else {
  warn "Skipping test 11 - no Math::GMPz\n";
  print "ok 11\n";
}

Rmpf_set_d($p, $double);

my $check = Rmpf_get_d($p);

if(abs($check - $double) < 0.0001) {print "ok 12\n"}
else {print "not ok 12\n"}

Rmpf_set_ui($p, $ui);

$check = Rmpf_get_ui($p);

if($check == $ui) {print "ok 13\n"}
else {print "not ok 13\n"}

Rmpf_set_si($p, $si);

$check = Rmpf_get_si($p);

if($check == $si) {print "ok 14\n"}
else {print "not ok 14\n"}

my @vals = Rmpf_get_d_2exp($r);

if($vals[0] < 0.7715663996200 &&
   $vals[0] > 0.7715663996199 &&
   $vals[1] == 573) {print "ok 15\n"}
else {print "not ok 15\n"}

Rmpf_add($q, $r, $r);
Rmpf_mul_ui($s, $r, 2);

if(!Rmpf_cmp($q, $s)) {print "ok 16\n"}
else {print "not ok 16\n"}

Rmpf_mul_2exp($q, $r, 1);

if(!Rmpf_cmp($q, $s)) {print "ok 17\n"}
else {print "not ok 17\n"}

Rmpf_div_2exp($q, $q, 1);

if(Rmpf_eq($q, $r, 64)) {print "ok 18\n"}
else {print "not ok 18\n"}

Rmpf_add_ui($q, $r, 1023);
Rmpf_sub_ui($q, $q, 1023);

if(!Rmpf_cmp($q, $r)) {print "ok 19\n"}
else {print "not ok 19\n"}

Rmpf_sub($s, $s, $r);

if(Rmpf_eq($s, $r, 64)) {print "ok 20\n"}
else {print "not ok 20\n"}

Rmpf_ui_sub($s, 11237, $r);
Rmpf_sub_ui($q, $r, 11237);
Rmpf_add($s, $s, $q);

if(!Rmpf_cmp_ui($s, 0)) {print "ok 21\n"}
else {print "not ok 21\n"}

Rmpf_neg($s, $r);

if(Rmpf_sgn($r) == 1 && Rmpf_sgn($s) == -1) {print "ok 22\n"}
else {print "not ok 22\n"}

Rmpf_abs($t, $s);

if(!Rmpf_cmp($t, $r)) {print "ok 23\n"}
else {print "not ok 23\n"}

my $str1 = Rmpf_get_str($t, 16, 0);
my $str2 = Rmpf_get_str($r, 16, 0);

#print "\nIN test1.t: $str1 $str2\n";

if($str1 eq $str2) {print "ok 24\n"}
else {print "not ok 24\n"}

Rmpf_reldiff($q, $s, $r);

if(Rmpf_cmp_d($q, -1.9999999) <= 0 && Rmpf_cmp_d($q, -2.0000001) >= 0) {print "ok 25\n"}
else {print "not ok 25\n"}

Rmpf_add($s, $r, $s);

if(!Rmpf_cmp_ui($s, 0)) {print "ok 26\n"}
else {print "not ok 26\n"}

Rmpf_set_d($q, $double);
Rmpf_pow_ui($s, $q, 2);
Rmpf_sqrt($s, $s);

if(Rmpf_eq($s, $q, 48)) {print "ok 27\n"}
else {print "not ok27\n"}

Rmpf_ceil($s, $q);

if(Rmpf_integer_p($s)) {print "ok 28\n"}
else {print "not ok 28\n"}

Rmpf_floor($s, $q);

if(Rmpf_integer_p($s)) {print "ok 29\n"}
else {print "not ok 29\n"}

Rmpf_trunc($s, $q);

if(Rmpf_integer_p($s)) {print "ok 30\n"}
else {print "not ok 30\n"}

Rmpf_div($s, $q, $r);
Rmpf_mul($t, $s, $r);

if(Rmpf_eq($t, $q, 48)) {print "ok 31\n"}
else {print "ok 31\n"}

Rmpf_div_ui($s, $q, 1234);
Rmpf_mul_ui($t, $s, 1234);

if(Rmpf_eq($t, $q, 48)) {print "ok 32\n"}
else {print "ok 32\n"}

Rmpf_sqrt_ui($t, 1000000);

if(!Rmpf_cmp_ui($t, 1000)) {print "ok 33\n"}
else {print "not ok 33\n"}

Rmpf_set_si($t, -1);

if(!Rmpf_fits_ulong_p($t)) {print "ok 34\n"}
else {print "not ok 34\n"}

if(Rmpf_fits_slong_p($t)) {print "ok 35\n"}
else {print "not ok 35\n"}

if(!Rmpf_fits_uint_p($t)) {print "ok 36\n"}
else {print "not ok 36\n"}

if(Rmpf_fits_sint_p($t)) {print "ok 37\n"}
else {print "not ok 37\n"}

if(!Rmpf_fits_ushort_p($t)) {print "ok 38\n"}
else {print "not ok 38\n"}

if(Rmpf_fits_sshort_p($t)) {print "ok 39\n"}
else {print "not ok 39\n"}

Rmpf_swap($q, $t);

if(!Rmpf_cmp_d($t, $double) && !Rmpf_cmp_si($q, -1)) {print "ok 40\n"}
else {print "ok 40\n"}

if($have_mpq) {
   Rmpf_set_q($q, $rat);
   if(Rmpf_integer_p($q)) {print "ok 41\n"}
   else {print "not ok 41\n"}
}
else {
  Rmpf_set_d($q, 123);
  warn "Skipping test 41 - no Math::GMPq\n";
  print "ok 41\n";
}

if($have_mpz) {
  my $str = '';

  for(1..64) {$str .= int(rand(2))}

  my $seed = Math::GMPz::Rmpz_init_set_str($str, 2);
  my $state = Math::GMPz::rand_init($seed);

  my @r = ();

  for(1..100) {push @r, Rmpf_init2(75)}


  my $ok = 1;
  Rmpf_urandomb(@r, $state, 75, scalar(@r));
  for(@r) {
     if(length(Rmpf_get_str($_, 2, 0)) > 80 || length(Rmpf_get_str($_, 2, 0)) < 40) {$ok = 0}
     }

  if($ok) {print "ok 42\n"}
  else {print "not ok 42\n"}

  Math::GMPz::rand_clear($state);
}
else {
  warn "Skipping test 42 - no Math::GMPz\n";
  print "ok 42\n";
}

my $w0 = Rmpf_init_set_ui(12345670);
my $w1 = Rmpf_init_set_si(-12345670);

Rmpf_add($w0, $w1, $w0);

if(!Rmpf_cmp_ui($w0, 0)) {print "ok 43\n"}
else {print "not ok 43\n"}

my $w2 = Rmpf_init_set_d(123.75);
my $dw2 = Rmpf_get_d($w2);

if(!Rmpf_cmp_d($w2, $dw2)) {print "ok 44\n"}
else {print "not ok 44\n"}

eval {$str = Math::GMPf::gmp_v();};

if($@ || $str =~ /[^0-9\.]/) {print "not ok 45\n"}
else {print "ok 45\n"}

#my $ofh = select(STDERR);
eval {Rmpf_printf("The version is %s. Values are %d %.2Ff %.3Ff\n", $str, 11, $w2, $w0);};
#select($ofh);

if(!$@) { print "not ok 46\n"}
else {print "ok 46\n"}

if(Rmpf_get_str($q, 62, 0) eq '0.1z@2') {print "ok 47\n"}
else {print "not ok 47\n"}

eval {Rmpf_get_str($q, -37, 0);};
if($@ =~ /is not in acceptable range/) {print "ok 48\n"}
else {print "not ok 48\n"}

@vals = Rmpf_get_d_2exp(Math::GMPf->new(0.125));
if($vals[0] == 0.5 && $vals[1] == -2) {print "ok 49\n"}
else {print "not ok 49 @vals\n"}


