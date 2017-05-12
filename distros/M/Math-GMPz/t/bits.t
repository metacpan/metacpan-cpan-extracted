use strict;
use warnings;
use Math::GMPz qw(:mpz);

#$| = 1;
print "1..11\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my
 $n1 = '10101010101010101111111111111111111111000000001110101';
my
 $n2 =  '1010101010101010000000000000000000000111111110001010';

my
 $n3 = '10101010101010101111111111111111111111000000011110101';

my $y = Rmpz_init_set_str($n1, 2);
my $x = Rmpz_init_set_str( $n2, 2);
my $z = Rmpz_init2(45);
my $q = Rmpz_init_set_str('113858109386036422141170669965214409511474201389', 10);
my $r = Rmpz_init();
my $ret;
my $ul = 1009;

Rmpz_and($z, $x, $y);
if(Rmpz_get_str($z, 2) eq '0')
     {print "ok 1\n"}
else {print "not ok 1\n"}

Rmpz_ior($z, $x, $y);
if(Rmpz_get_str($z, 2) eq '11111111111111111111111111111111111111111111111111111')
     {print "ok 2\n"}
else {print "not ok 2\n"}

Rmpz_xor($z, $x, $y);
if(Rmpz_get_str($z, 2) eq '11111111111111111111111111111111111111111111111111111')
     {print "ok 3\n"}
else {print "not ok 3\n"}

Rmpz_com($z, $x);
if(Rmpz_get_str($z, 2) eq '-1010101010101010000000000000000000000111111110001011')
     {print "ok 4\n"}
else {print "not ok 4\n"}

if(Rmpz_popcount($x) == 18)
     {print "ok 5\n"}
else {print "not ok 5\n"}

if(Rmpz_hamdist($x, $y) == 53)
     {print "ok 6\n"}
else {print "not ok 6\n"}

if(Rmpz_scan0($x, 12) == 15)
     {print "ok 7\n"}
else {print "not ok 7\n"}

if(Rmpz_scan1($x, 12) == 12)
     {print "ok 8\n"}
else {print "not ok 8\n"}

Rmpz_set($q, $x);

if(Rmpz_tstbit($q, 20)) {Rmpz_clrbit($q, 20)}
else {Rmpz_setbit($q, 20)}
if(Rmpz_tstbit($q, 20)) {Rmpz_clrbit($q, 20)}
else {Rmpz_setbit($q, 20)}
if(!Rmpz_cmp($q, $x))
     {print "ok 9\n"}
else {print "not ok 9\n"}

my $s =   Rmpz_init_set_str('1000011000001', 2);
my $s_copy = Rmpz_init_set_str('1000011000001', 2);;
my $cmp = Rmpz_init_set_str('1000001000001', 2);

Rmpz_combit($s, 7);

if($s == $cmp) {print "ok 10\n"}
else {print "not ok\n$s $cmp\n"}

Rmpz_combit($cmp, 7);

if($cmp == $s_copy) {print "ok 11\n"}
else {print "not ok 11\n $cmp $s_copy\n"}
