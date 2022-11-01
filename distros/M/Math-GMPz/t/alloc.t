use Math::GMPz qw(:mpz);

use strict;
use warnings;

$| = 1;
print "1..21\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $ok = '';

my $have_mpf = 0;
my $have_mpq = 0;
my($float, $rat);

eval{require Math::GMPf};
if(!$@) {$have_mpf = 1}

eval{require Math::GMPq};
if(!$@) {$have_mpq = 1}

my $n1 = '101101101101101101101101101101101101101101101101101101101101101101101101101';
my $n2 =  '110110110110110110110110110110110110110110110110110110110110110110110110110';

my $x = Rmpz_init_set_str($n1, 2);
my $y = Rmpz_init_set_str( $n2, 2);

if(Rmpz_get_str($x, 10) eq '26984951330683686935405'
   &&
   lc(Rmpz_get_str($y, 16)) eq '6db6db6db6db6db6db6')
     {print "ok 1\n"}
else {print "not ok 1\n"}

Rmpz_swap($x, $y);

if(Rmpz_get_str($y, 10) eq '26984951330683686935405'
   &&
   lc(Rmpz_get_str($x, 16)) eq '6db6db6db6db6db6db6')
     {print "ok 2\n"}
else {print "not ok 2\n"}

my $z = Rmpz_init2(45);
my $q = Rmpz_init();
my $r = Rmpz_init2(50);

Rmpz_set($z, $y);
if(Rmpz_get_str($z, 32) eq Rmpz_get_str($y, 32))
     {print "ok 3\n"}
else {print "not ok 3\n"}

Rmpz_set($q, $y);

Rmpz_realloc2($z, 30);
Rmpz_realloc2($q, 100);

$ok .= 'a' if Rmpz_get_str($z, 2) eq '0';
$ok .= 'b' if Rmpz_get_str($q, 2) eq Rmpz_get_str($y, 2);
if($ok eq 'ab')  {print "ok 4\n"}
else {print "not ok 4 $ok\n"}

Rmpz_set_si($z, -12345);
if(Rmpz_get_str($z, 10) eq '-12345')
     {print "ok 5\n"}
else {print "not ok 5\n"}

Rmpz_set_ui($z, 12345);
if(Rmpz_get_str($z, 10) eq '12345')
     {print "ok 6\n"}
else {print "not ok 6\n"}

Rmpz_set_d($z, -12345.00000001);
if(Rmpz_get_str($z, 10) eq '-12345')
     {print "ok 7\n"}
else {print "not ok 7\n"}


Rmpz_set_str($z, '9999999999999999999999', 33);
if(Rmpz_get_str($z, 33) eq '9999999999999999999999')
     {print "ok 8\n"}
else {print "not ok 8\n"}

# Two stupid tests that rely on sizeof(long) == 4
# (which is not always the case).
# Let's just remove tests 9 and 10

#my $truncated = Rmpz_get_ui($y);
#if($truncated == 1840700269)
print "ok 9\n";
#else {print "not ok 9\n"}

#$truncated = Rmpz_get_si($y);
#if($truncated == 1840700269)
print "ok 10\n";
#else {print "not ok 10\n"}

my $exp2 = Rmpz_init_set_str('1010101010101010000000000000000000000111111110001010', 2);

my @log2 = Rmpz_get_d_2exp($exp2);
if($log2[0] > 0.66665649414787
   &&
   $log2[0] < 0.66665649414788
   &&
   $log2[1] == 52)
     {print "ok 11\n"}
else {print "not ok 11\n"}

# For 32-bit limb value should be: 1840700269
# For 64-bit limb value should be: 15811494920322472813

if(Rmpz_getlimbn($y, 0) == 1840700269 ||
   Rmpz_getlimbn($y, 0) == 15811494920322472813)
     {print "ok 12\n"}
else {print "not ok 12, got: ", Rmpz_getlimbn($y, 0), "\n"}

if($have_mpf){
  $float = Math::GMPf::Rmpf_init2(200);
  Math::GMPf::Rmpf_set_d($float, 123.111);
  Rmpz_set_f($x, $float);
  if(!Rmpz_cmp_ui($x, 123)) {print "ok 13\n"}
  else {print "not ok 13\n"}
}
else {
  warn "Skipping test 13 - no Math::GMPf\n";
  print "ok 13\n";
}

if($have_mpq){
  $rat = Math::GMPq::Rmpq_init();
  Math::GMPq::Rmpq_set_ui($rat, 123, 1);
  Rmpz_set_q($x, $rat);
  if(!Rmpz_cmp_ui($x, 123)) {print "ok 14\n"}
  else {print "not ok 14\n"}
}
else {
  warn "Skipping test 14 - no Math::GMPq\n";
  print "ok 14\n";
}

my $str = '4321' x 50;

my $double = 211.12345;

my $s0 = Rmpz_init();
Rmpz_set_str($s0, $str, 10);
my $s1 = Rmpz_init_set_str($str, 10);

if(!Rmpz_cmp($s0, $s1)) {print "ok 15\n"}
else {print "not ok 15\n"}

my $unsigned = Rmpz_init_set_ui(123456789);
my $signed = Rmpz_init_set_si(-123456789);

Rmpz_add($signed, $unsigned, $signed);
if(!Rmpz_cmp_si($signed, 0)) {print "ok 16\n"}
else {print "not ok 16\n"}

my $s2 = Rmpz_init_set_d($double);
if(!Rmpz_cmp_ui($s2, int($double))) {print "ok 17\n"}
else {print "not ok 17\n"}

Rmpz_set_str($x, '0xFFFFFFFFFFFFFFF', 0);
Rmpz_set_str($y, '0xfffffffffffffff', 0);
Rmpz_set_str($z, '0XFFFFFFFFFFFFFFF', 0);
Rmpz_set_str($q, '0Xfffffffffffffff', 0);
Rmpz_set_str($s0, '077777777777777777777', 0);
Rmpz_set_str($s1, '1152921504606846975', 0);

if(!Rmpz_cmp($x, $y) && !Rmpz_cmp($x, $z)&& !Rmpz_cmp($x, $q) &&
   !Rmpz_cmp($x, $s0) && !Rmpz_cmp($x, $s1)) {print "ok 18\n"}
else {print "not ok 18\n"}

my $x10 = Rmpz_init_set_str('0xFFFFFFFFFFFFFFF', 0);
my $y10 = Rmpz_init_set_str('0xfffffffffffffff', 0);
my $z10 = Rmpz_init_set_str('0XFFFFFFFFFFFFFFF', 0);
my $q10 = Rmpz_init_set_str('0Xfffffffffffffff', 0);
my $s10 = Rmpz_init_set_str('077777777777777777777', 0);
my $s11 = Rmpz_init_set_str('1152921504606846975', 0);

if(!Rmpz_cmp($x10, $y10) && !Rmpz_cmp($x10, $z10)&& !Rmpz_cmp($x10, $q10) &&
   !Rmpz_cmp($x10, $s10) && !Rmpz_cmp($x10, $s11)) {print "ok 19\n"}
else {print "not ok 19\n"}

eval {$ok = Math::GMPz::gmp_v();};

if($@ || $ok =~ /[^0-9\.]/) {print "not ok 20\n"}
else {print "ok 20\n"}

#my $ofh = select(STDERR);
eval {Rmpz_printf("The version is %s. Values are %d %#Zo %#Zo\n", $ok, 11, $x10, $y10);};
#select($ofh);

if($@) {print "ok 21\n"}
else {print "not ok 21\n"}

