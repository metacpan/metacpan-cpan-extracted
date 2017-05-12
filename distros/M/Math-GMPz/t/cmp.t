use strict;
use warnings;
use Math::GMPz qw(:mpz);

#$| = 1;
print "1..8\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my
 $n1 = '10101010101010101111111111111111111111000000001110101';
my
 $n2 =  '1010101010101010000000000000000000000111111110001010';

my $y = Rmpz_init_set_str($n1, 2);
my $x = Rmpz_init_set_str( $n2, 2);
my $z = Rmpz_init2(45);
my $q = Rmpz_init_set_str('113858109386036422141170669965214409511474201389', 10);
my $r = Rmpz_init();
my $ret;
my $ul = 1009;

Rmpz_set($z, $x);
my
 $zero = Rmpz_cmp($z, $x);
if(Rmpz_cmp($x, $y) == -(Rmpz_cmp($y, $x))
   &&
   $zero == 0)
     {print "ok 1\n"}
else {print "not ok 1\n"}

$ret = Rmpz_cmp_d($x, 12345678.99999012);
if($ret > 0)
     {print "ok 2\n"}
else {print "not ok 2\n"}

$ret = Rmpz_cmp_si($x, -12345);
if($ret > 0)
     {print "ok 3\n"}
else {print "not ok 3\n"}

$ret = Rmpz_cmp_ui($x, 12345);
if($ret > 0)
     {print "ok 4\n"}
else {print "not ok 4\n"}

Rmpz_set($r, $x);
Rmpz_mul_si($r, $r, -1);

if(!Rmpz_cmpabs($r, $x))
     {print "ok 5\n"}
else {print "not ok 5\n"}

my
 $double = 12345678.90123456;
Rmpz_set_d($r, $double);
Rmpz_mul_si($r, $r, -1);
if(Rmpz_cmpabs_d($r, $double) < 0)
     {print "ok 6\n"}
else {print "not ok 6\n"}

Rmpz_set_ui($r, $ul);
Rmpz_mul_si($r, $r, -1);

if(!Rmpz_cmpabs_ui($r, $ul))
     {print "ok 7\n"}
else {print "not ok 7\n"}

if(Rmpz_sgn($r) == -1
   &&
   Rmpz_sgn($x) == 1)
     {print "ok 8\n"}
else {print "not ok 8\n"}
