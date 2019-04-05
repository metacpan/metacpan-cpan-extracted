#!perl

use Test2::V0 qw'is float done_testing';

use Math::Lapack::Matrix;
use Math::Lapack::Expr;

my $A = Math::Lapack::Matrix->new([
					[  0,  1.5,  -10, 6],
					[  3, 4.55, 0.99, 7],
					[0.5,   -8,    3, 8]
				]);

my $B = Math::Lapack::Matrix->new(
				[
					[3, 7],
					[15, 3.4]
				]
);

# Transpose
my $C = $A->transpose();
is($C->rows, 4, "Right number of rows");
is($C->columns, 3, "Right number of columns");
_float($C->get_element(0,0), 0, "Transpose: correct value 0,0");
_float($C->get_element(0,1), 3, "Transpose: correct value 0,1");
_float($C->get_element(0,2), 0.5, "Transpose: correct value 0,2");
_float($C->get_element(1,0), 1.5, "Transpose: correct value 1,0");
_float($C->get_element(1,1), 4.55, "Transpose: correct value 1,1");
_float($C->get_element(1,2), -8, "Transpose: correct value 1,2");
_float($C->get_element(2,0), -10, "Transpose: correct value 2,0");
_float($C->get_element(2,1), .99, "Transpose: correct value 2,1");
_float($C->get_element(2,2), 3, "Transpose: correct value 2,2");
_float($C->get_element(3,0), 6, "Transpose: correct value 3,0");
_float($C->get_element(3,1), 7, "Transpose: correct value 3,1");
_float($C->get_element(3,2), 8, "Transpose: correct value 3,2");


$C = $A->T;
is($C->rows, 4, "Right number of rows");
is($C->columns, 3, "Right number of columns");
_float($C->get_element(0,0), 0, "Transpose: correct value 0,0");
_float($C->get_element(0,1), 3, "Transpose: correct value 0,1");
_float($C->get_element(0,2), 0.5, "Transpose: correct value 0,2");
_float($C->get_element(1,0), 1.5, "Transpose: correct value 1,0");
_float($C->get_element(1,1), 4.55, "Transpose: correct value 1,1");
_float($C->get_element(1,2), -8, "Transpose: correct value 1,2");
_float($C->get_element(2,0), -10, "Transpose: correct value 2,0");
_float($C->get_element(2,1), .99, "Transpose: correct value 2,1");
_float($C->get_element(2,2), 3, "Transpose: correct value 2,2");
_float($C->get_element(3,0), 6, "Transpose: correct value 3,0");
_float($C->get_element(3,1), 7, "Transpose: correct value 3,1");
_float($C->get_element(3,2), 8, "Transpose: correct value 3,2");


$C = transpose($A);
is($C->rows, 4, "Right number of rows");
is($C->columns, 3, "Right number of columns");
_float($C->get_element(0,0), 0, "Transpose: correct value 0,0");
_float($C->get_element(0,1), 3, "Transpose: correct value 0,1");
_float($C->get_element(0,2), 0.5, "Transpose: correct value 0,2");
_float($C->get_element(1,0), 1.5, "Transpose: correct value 1,0");
_float($C->get_element(1,1), 4.55, "Transpose: correct value 1,1");
_float($C->get_element(1,2), -8, "Transpose: correct value 1,2");
_float($C->get_element(2,0), -10, "Transpose: correct value 2,0");
_float($C->get_element(2,1), .99, "Transpose: correct value 2,1");
_float($C->get_element(2,2), 3, "Transpose: correct value 2,2");
_float($C->get_element(3,0), 6, "Transpose: correct value 3,0");
_float($C->get_element(3,1), 7, "Transpose: correct value 3,1");
_float($C->get_element(3,2), 8, "Transpose: correct value 3,2");


# inverse
my $D = $B->inverse();
is($D->rows, 2, "Right number of rows");
is($D->columns, 2, "Right number of columns");
_float($D->get_element(0,0), -3.5864982e-2, "Inverse: correct value 0,0");
_float($D->get_element(0,1), 7.3839662e-2, "Inverse: correct value 0,1");
_float($D->get_element(1,0), 1.5822785e-1, "Inverse: correct value 1,0");
_float($D->get_element(1,1), -3.1645570e-2, "Inverse: correct value 1,1");


$D = inverse($B);
is($D->rows, 2, "Right number of rows");
is($D->columns, 2, "Right number of columns");
_float($D->get_element(0,0), -3.5864982e-2, "Inverse: correct value 0,0");
_float($D->get_element(0,1), 7.3839662e-2, "Inverse: correct value 0,1");
_float($D->get_element(1,0), 1.5822785e-1, "Inverse: correct value 1,0");
_float($D->get_element(1,1), -3.1645570e-2, "Inverse: correct value 1,1");



done_testing;


sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.00001), $c);
}
