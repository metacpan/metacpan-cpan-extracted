use strict;
use warnings;
use Math::GMPz qw(:mpz);

#$| = 1;
print "1..34\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my
 $n1 = '10101010101010101111111111111111111111000000001110101';
my
 $n2 =  '1010101010101010000000000000000000000111111110001010';

my $y = Rmpz_init_set_str($n1, 2);
my $x = Rmpz_init_set_str( $n2, 2);
my $z = Rmpz_init();
my $zprev = Rmpz_init();
my $q = Rmpz_init_set_str('113858109386036422141170669965214409511474201389', 10); # Not a prime
my $r = Rmpz_init2(45);
my $ret;
my $ul = 1009;

if(!Rmpz_probab_prime_p($q, 5))
     {print "ok 1\n"}
else {print "not ok 1\n"}

#$q => 113858109386036422141170669965214409511474201389

my $ok = '';
Rmpz_nextprime($z, $q);
if(Rmpz_get_str($z, 10) eq '113858109386036422141170669965214409511474201407')
     {$ok .= 'a'}

if(60300 <= Math::GMPz::__GNU_MP_RELEASE()) {
     Rmpz_prevprime($zprev, $z);
     $ok .= 'b' if $zprev == '113858109386036422141170669965214409511474201237';
     $ok .= 'c' if Rmpz_probab_prime_p($zprev, 10);
}
else {
     warn "Rmpz_prevprime() not available\n";
     $ok .= 'bc';
}

if($ok eq 'abc') { print "ok 2\n" }
else {
     warn "2: Got '$ok'\n";
     print "not ok 2\n";
}

$ok = '';

Rmpz_set($q, $z);
Rmpz_add_ui($q, $q, 2);
Rmpz_nextprime($r, $q);

Rmpz_gcd($z, $q, $r);
if(Rmpz_get_str($z, 10) eq '1')
     {print "ok 3\n"}
else {print "not ok 3\n"}

$ret = Rmpz_gcd_ui($z, $q, $ul);
if(Rmpz_get_str($z, 10) eq '1' && $ret == 1)
     {print "ok 4\n"}
else {print "not ok 4\n"}

my
 $g = Rmpz_init2(50);
my
 $s = Rmpz_init2(50);
my
 $t = Rmpz_init2(50);

Rmpz_gcdext($g, $s, $t, $x, $y);
Rmpz_mul($q, $s, $x);
Rmpz_mul($r, $t, $y);
Rmpz_add($z, $q, $r);
if(Rmpz_get_str($z, 22) eq Rmpz_get_str($g, 22))
     {print "ok 5\n"}
else {print "not ok 5\n"}

my ($g_copy, $x_copy, $y_copy, $q_copy) = ($g, $x, $y, $q);

Rmpz_lcm($z, $x, $y);
if(Rmpz_get_str($z, 10) eq '18028670985685207461102483753490')
     {print "ok 6\n"}
else {print "not ok 6\n"}

Rmpz_lcm_ui($z, $x, $ul);
if(Rmpz_get_str($z, 10) eq '3029375124076146410')
     {print "ok 7\n"}
else {print "not ok 7\n"}

$ret = Rmpz_invert($z, $x, $y);
Rmpz_mul($z, $z, $x);
Rmpz_mod($r, $z, $y);
if($ret
   &&
   Rmpz_get_str($r, 30) eq '1')
     {print "ok 8\n"}
else {print "not ok 8\n"}

if(!Rmpz_jacobi($z, $q))
     {print "ok 9\n"}
else {print "not ok 9\n"}

if(!Rmpz_legendre($z, $q))
     {print "ok 10\n"}
else {print "not ok 10\n"}

if(!Rmpz_kronecker($z, $q))
     {print "ok 11\n"}
else {print "not ok 11\n"}

if(Rmpz_kronecker_si($z, -1234567) == -1)
     {print "ok 12\n"}
else {print "not ok 12\n"}

if(Rmpz_kronecker_ui($z, 1234567) == -1)
     {print "ok 13\n"}
else {print "not ok 13\n"}

if(Rmpz_si_kronecker(-1234567, $z) == -1)
     {print "ok 14\n"}
else {print "not ok 14\n"}

if(Rmpz_ui_kronecker(1234567, $z) == -1)
     {print "ok 15\n"}
else {print "not ok 15\n"}

Rmpz_set_str($z, '30414093201713378043612608166064768844377641568960512000000000000', 10);
Rmpz_set_ui($q, 10);

$ok = Rmpz_remove($z, $z, $q);
if($ok == 12
   &&
   Rmpz_get_str($z, 10) eq '30414093201713378043612608166064768844377641568960512')
     {print "ok 16\n"}
else {print "not ok 16\n"}

Rmpz_fac_ui($z, 50);
if(Rmpz_get_str($z, 10) eq '30414093201713378043612608166064768844377641568960512000000000000')
     {print "ok 17\n"}
else {print "not ok 17\n"}

Rmpz_bin_ui($z, $x, 7);
if(Rmpz_get_str($z, 10) eq '436317551922400232982237419936578885282107018468817954394524435184434624720242570984978800842744037293560')
     {print "ok 18\n"}
else {print "not ok 18\n"}

Rmpz_bin_uiui($z, 123456, 6);
if(Rmpz_get_str($z, 10) eq '4916861164227040726409882016')
     {print "ok 19\n"}
else {print "not ok 19\n"}

Rmpz_fib_ui($z, 100);
if(Rmpz_get_str($z, 10) eq '354224848179261915075')
     {print "ok 20\n"}
else {print "not ok 20\n"}

Rmpz_fib2_ui($q, $r, 100);

if(Rmpz_get_str($q, 10) eq '354224848179261915075'
   &&
   Rmpz_get_str($r, 10) eq '218922995834555169026')
     {print "ok 21\n"}
else {print "not ok 21\n"}

Rmpz_lucnum_ui($z, 100);
if(Rmpz_get_str($z, 10) eq '792070839848372253127')
     {print "ok 22\n"}
else {print "not ok 22\n"}

Rmpz_lucnum2_ui($q, $r, 100);
if(Rmpz_get_str($q, 10) eq '792070839848372253127'
   &&
   Rmpz_get_str($r, 10) eq '489526700523968661124')
     {print "ok 23\n"}
else {print "not ok 23\n"}

$ret = Rmpz_gcd_ui($z, $q, 0);
if($ret == 0 && $z == $q) {print "ok 24\n"}
else {
  warn "\$ret: $ret\n\$z: $z\n\$q: $q\n";
  print "not ok 24\n";
}

$ret = Rmpz_gcd_ui($Math::GMPz::NULL, $q, 0);
if($ret == 0) {print "ok 25\n"}
else {
  warn "\$ret: $ret\n";
  print "not ok 25\n";
}

Rmpz_set_ui($q, 24);
$ret = Rmpz_gcd_ui($z, $q, 0);
if($ret == 24 && $z == 24) {print "ok 26\n"}
else {
  warn "\$ret: $ret\n\$z: $z\n\$q: $q\n";
  print "not ok 26\n";
}

$ret = Rmpz_gcd_ui($Math::GMPz::NULL, $q, 0);
if($ret == 24) {print "ok 27\n"}
else {
  warn "\$ret: $ret\n";
  print "not ok 27\n";
}

$ret = Rmpz_gcd_ui($Math::GMPz::NULL, $q, 17);
if($ret == 1) {print "ok 28\n"}
else {
  warn "\$ret: $ret\n";
  print "not ok 28\n";
}

Rmpz_gcdext($g, $s, $Math::GMPz::NULL, $x_copy, $y_copy);
Rmpz_mul($q, $s, $x_copy);
if($g == $g_copy && $q == $q_copy) {print "ok 29\n"}
else {
  warn
  print "not ok 29\n";
}

Rmpz_bin_si($q, Math::GMPz->new(-5), Math::GMPz->new(-10));
if($q == -126) {print "ok 30\n"}
else {
  warn "\n  Expected -126\n  Got $q\n";
  print "not ok 30\n";
}

Rmpz_bin_si($q, Math::GMPz->new(5), Math::GMPz->new(-10));
if($q == 0) {print "ok 31\n"}
else {
  warn "\n  Expected 0\n Got $q\n";
  print "not ok 31\n";
}

Rmpz_bin_si($q, Math::GMPz->new(-11), Math::GMPz->new(-10));
if($q == 0) {print "ok 32\n"}
else {
  warn "\n  Expected 0\n Got $q\n";
  print "not ok 32\n";
}

Rmpz_bin_ui($z, Math::GMPz->new(10), Math::GMPz->new(15));
Rmpz_bin_si($q, Math::GMPz->new(10), Math::GMPz->new(15));
if($z == $q) {print "ok 33\n"}
else {print "not ok 33\n"}

Rmpz_bin_ui($z, Math::GMPz->new(-10), Math::GMPz->new(15));
Rmpz_bin_si($q, Math::GMPz->new(-10), Math::GMPz->new(15));
if($z == $q) {print "ok 34\n"}
else {print "not ok 34\n"}

