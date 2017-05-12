use Math::Int128 qw(int128 :op);
use Math::GMPz qw(:mpz);
use Benchmark qw(:all);

$count = 40000;

$mpz1  = Math::GMPz->new('676469752303423489');
$mpz2  = Math::GMPz->new('776469752999423489');
$i_1   = int128("$mpz1");
$i_2   = int128("$mpz2");

$mpz_sub = Math::GMPz->new('976469752313423489');
$i_sub   = int128("$mpz_sub");

$mpz_div = Math::GMPz->new('76469752313423489');
$i_div   = int128("$mpz_div");

$mpz_ret = Rmpz_init2(128);
$i_ret = int128();

use warnings;

print "
******************
**MULTIPLICATION**
******************\n\n";

cmpthese(-2, {
    'mul_M::I' => '$ri = Math::Int128::_mul($i_1, $i_2, 0)',
    'mul_M::I2'=> 'int128_mul($i_ret, $i_1, $i_2)',
    'mul_M::G1'=> '$mpz_ret = $mpz1 * $mpz2',
    'mul_M::G2'=> 'Rmpz_mul($mpz_ret, $mpz1, $mpz2)',
});

die "Error 1:\n$ri\n$mpz_ret\n$i_ret\n" if $ri != int128("$mpz_ret")
 || $ri != int128('525258301482620425304858018020933121') || $ri != $i_ret;


$i_1 *= $i_1;
$i_2 *= $i_2;
$mpz1 *= $mpz1;
$mpz2 *= $mpz2;

# print "i_1: $i_1, i_2: $i_2\n";


print "
******************
*****DIVISION*****
******************\n\n";

cmpthese(-2, {
    'div_M::I' => '$ri = Math::Int128::_div($i_1, $i_div, 0)',
    'div_M::I2'=> 'int128_div($i_ret, $i_1, $i_div)',
    'div_M::G1'=>'$mpz_ret = $mpz1 / $mpz_div',
    'div_M::G2'=> 'Rmpz_tdiv_q($mpz_ret, $mpz1, $mpz_div)',
});

die "Error 2:\n$ri\n$mpz_ret\n$i_ret\n" if $ri != int128("$mpz_ret")
 || $ri != int128('5984213521522366751') || $ri != $i_ret;

print"
******************
*****ADDITION*****
******************\n\n";

cmpthese(-2, {
    'add_M::I'  => '$ri = Math::Int128::_add($i_1, $i_2, 0)',
    'add_M::I2' => 'int128_add($i_ret, $i_1, $i_2)',
    'add_M::G1' => '$mpz_ret = $mpz1  + $mpz2',
    'add_M::G2' => 'Rmpz_add($mpz_ret, $mpz1, $mpz2)',
});

die "Error 3:\n$ri\n$mpz_ret\n$i_ret\n" if $ri != int128("$mpz_ret")
 || $ri != int128('1060516603104440851094132036041866242') || $ri != $i_ret;

print "
******************
****SUBTRACTION***
******************\n\n";

cmpthese(-2, {
    'sub_M::I'  => '$ri = Math::Int128::_sub($i_1, $i_sub, 0)',
    'sub_M::I2' => 'int128_sub($i_ret, $i_1, $i_sub)',
    'sub_M::G1' => '$mpz_ret = $mpz1 - $mpz_sub',
    'sub_M::G2' => 'Rmpz_sub($mpz_ret, $mpz1, $mpz_sub)',
});

die "Error 4:\n$ri\n$mpz_ret\n$i_ret\n" if $ri != int128("$mpz_ret")
 || $ri != int128('457611325781455127825205517363509632') || $ri != $i_ret;
