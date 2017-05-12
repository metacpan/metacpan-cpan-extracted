use strict;
use warnings;
use Math::GMPz qw(:mpz);

#$| = 1;
print "1..19\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my
 $n1 = '10101010101010101111111111111111111111000000001110101';

my
 $n2 =  '1010101010101010000000000000000000000111111110001010';

my $x = Rmpz_init_set_str( $n2, 2);
my $y = Rmpz_init_set_str( $n1, 2);
my $z = Rmpz_init_set_str('24018831509027921', 10);
my $q = Rmpz_init();
my $r = Rmpz_init2(50);

my $ul = 1009;
my $ret;



Rmpz_tdiv_q($q, $z, $x);
if(Rmpz_get_str($q, 10) eq '8')
     {print "ok 1\n"}
else {print "not ok 1\n"}

Rmpz_tdiv_r($r, $z, $x);
if(Rmpz_get_str($r, 10) eq '1')
     {print "ok 2\n"}
else {print "not ok 2\n"}

Rmpz_tdiv_qr($q, $r, $z, $x);
if(Rmpz_get_str($r, 10) eq '1'
   &&
   Rmpz_get_str($q, 10) eq '8')
     {print "ok 3\n"}
else {print "not ok 3\n"}

$ret = Rmpz_tdiv_q_ui($q, $z, $ul);
if($ret == 653
   &&
   Rmpz_get_str($q, 10) eq '23804590197252')
     {print "ok 4\n"}
else {print "not ok 4\n"}

$ret = Rmpz_tdiv_r_ui($r, $z, $ul);
if($ret == 653
   &&
   Rmpz_get_str($r, 10) eq '653')
     {print "ok 5\n"}
else {print "not ok 5\n"}

$ret = Rmpz_tdiv_qr_ui($q, $r, $z, $ul);
if($ret == 653
   &&
   Rmpz_get_str($r, 10) eq '653'
   &&
   Rmpz_get_str($q, 10) eq '23804590197252')
     {print "ok 6\n"}
else {print "not ok 6\n"}

$ret = Rmpz_tdiv_ui($z, $ul);
if($ret == 653)
     {print "ok 7\n"}
else {print "not ok 7\n"}

Rmpz_tdiv_q_2exp($q, $z, 3);
if(Rmpz_get_str($q, 10) eq '3002353938628490')
     {print "ok 8\n"}
else {print "not ok 8\n"}

Rmpz_tdiv_r_2exp($r, $z, 3);
if(Rmpz_get_str($r, 10) eq '1')
     {print "ok 9\n"}
else {print "not ok 9\n"}

Rmpz_mod($r, $z, $x);
if(Rmpz_get_str($r, 13) eq '1')
     {print "ok 10\n"}
else {print "not ok 10\n"}

$ret = Rmpz_mod_ui($r, $z, $ul);
if(Rmpz_get_str($r, 10) eq $ret)
     {print "ok 11\n"}
else {print "not ok 11\n"}

Rmpz_mul($z, $x, $y);

Rmpz_divexact($z, $z, $x);
if(Rmpz_get_str($z, 21) eq Rmpz_get_str($y, 21))
     {print "ok 12\n"}
else {print "not ok 12\n"}

Rmpz_mul_ui($z, $y, $ul);

Rmpz_divexact_ui($z, $z, $ul);
if(Rmpz_get_str($z, 21) eq Rmpz_get_str($y, 21))
     {print "ok 13\n"}
else {print "not ok 13\n"}

$ret = Rmpz_divisible_p($x, $y);
if(!$ret)
     {print "ok 14\n"}
else {print "not ok 14\n"}

$ret = Rmpz_divisible_ui_p($x, $ul);
if(!$ret)
     {print "ok 15\n"}
else {print "not ok 15\n"}

$ret = Rmpz_divisible_2exp_p($x, 3);
if(!$ret)
     {print "ok 16\n"}
else {print "not ok 16\n"}

$ret = Rmpz_congruent_p($z, $x, $y);
if(!$ret)
     {print "ok 17\n"}
else {print "not ok 17\n"}

$ret = Rmpz_congruent_ui_p($z, $x, $ul);
if(!$ret && Rmpz_congruent_ui_p($z, 1, 10))
     {print "ok 18\n"}
else {print "not ok 18\n"}

$ret = Rmpz_congruent_2exp_p($z, $x, 3);
if(!$ret)
     {print "ok 19\n"}
else {print "not ok 19\n"}
