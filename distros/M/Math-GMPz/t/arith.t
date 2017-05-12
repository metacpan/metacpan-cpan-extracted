use strict;
use warnings;
use Math::GMPz qw(:mpz);

#$| = 1;
print "1..15\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my
 $n1 = '10101010101010101111111111111111111111000000001110101';
my
 $n2 =  '1010101010101010000000000000000000000111111110001010';

my $y = Rmpz_init_set_str($n1, 2);
my $x = Rmpz_init_set_str( $n2, 2);
my $z = Rmpz_init();

Rmpz_add($z, $x, $y);
if(Rmpz_get_str($z, 10) eq '9007199254740991')
     {print "ok 1\n"}
else {print "not ok 1\n"}

my
$ul = 1009;

Rmpz_add_ui($z, $z, $ul);
if(Rmpz_get_str($z, 10) eq '9007199254742000')
     {print "ok 2\n"}
else {print "not ok 2\n"}

Rmpz_sub($z, $z, $x);
if(Rmpz_get_str($z, 10) eq '6004845316113510')
     {print "ok 3\n"}
else {print "not ok 3\n"}

Rmpz_sub_ui($z, $z, $ul);
if(Rmpz_get_str($z, 10) eq Rmpz_get_str($y, 10))
     {print "ok 4\n"}
else {print "not ok 4\n"}

Rmpz_ui_sub($z, $ul, $y);
if(Rmpz_get_str($z, 10) eq '-6004845316111492')
     {print "ok 5\n"}
else {print "not ok 5\n"}

Rmpz_mul($z, $x, $y);
if(Rmpz_get_str($z, 10) eq '18028670985685207461102483753490')
     {print "ok 6\n"}
else {print "not ok 6\n"}

Rmpz_mul_si($z, $z, -$ul);
if(Rmpz_get_str($z, 10) eq '-18190929024556374328252406107271410')
     {print "ok 7\n"}
else {print "not ok 7\n"}

Rmpz_mul_ui($z, $z, $ul);
if(Rmpz_get_str($z, 10) eq '-18354647385777381697206677762236852690')
     {print "ok 8\n"}
else {print "not ok 8\n"}

Rmpz_addmul($z, $x, $y);
if(Rmpz_get_str($z, 10) eq '-18354629357106396011999216659753099200')
     {print "ok 9\n"}
else {print "not ok 9\n"}

Rmpz_addmul_ui($z, $x, $ul);
if(Rmpz_get_str($z, 10) eq '-18354629357106396008969841535676952790')
     {print "ok 10\n"}
else {print "not ok 10\n"}

Rmpz_mul_si($z, $z, -1);

Rmpz_submul($z, $x, $y);
if(Rmpz_get_str($z, 10) eq '18354611328435410323762380433193199300')
     {print "ok 11\n"}
else {print "not ok 11\n"}

Rmpz_submul_ui($z, $x, $ul);
if(Rmpz_get_str($z, 10) eq '18354611328435410320733005309117052890')
     {print "ok 12\n"}
else {print "not ok 12\n"}

Rmpz_mul_2exp($z, $x, 3);
if(Rmpz_get_str($z, 10) eq '24018831509027920')
     {print "ok 13\n"}
else {print "not ok 13\n"}

Rmpz_neg($z, $z);
if(Rmpz_get_str($z, 10) eq '-24018831509027920')
     {print "ok 14\n"}
else {print "not ok 14\n"}

Rmpz_abs($z, $z);
if(Rmpz_get_str($z, 10) eq '24018831509027920')
     {print "ok 15\n"}
else {print "not ok 15\n"}
