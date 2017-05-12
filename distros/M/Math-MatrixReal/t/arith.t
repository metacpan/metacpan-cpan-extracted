use Test::More tests => 4;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

$matrix = Math::MatrixReal->new_random(20);
$matrix2 = $matrix->shadow();
$matrix2->one();
$matrix3 = $matrix;

ok_matrix( $matrix * 2 , $matrix + $matrix, ' twice a = a + a ' );

$matrix3 -= $matrix2;
ok_matrix( $matrix3 + $matrix2, $matrix, ' subtraction undoes addition' );

$matrix3 = $matrix;
$matrix3 += $matrix2;
ok_matrix($matrix3 - $matrix2, $matrix, ' addition undoes subtraction' );

$matrix3 = $matrix;
$matrix3 *= 5;
ok_matrix( $matrix3, $matrix * 5, 'overloaded *= works' );

