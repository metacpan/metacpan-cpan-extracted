#!perl

use Test2::V0;

use Math::Lapack::Matrix;
my $A = Math::Lapack::Matrix->new([
					[  0,  1.5,  -10, 6],
					[  3, 4.55, 0.99, 7],
					[0.5,   -8,    3, 8]
				]);

my $M = Math::Lapack::Matrix->new(
				[
					[.3, 1.5, 10, 6],
					[3, 4.55, .99, 7],
					[.5, .001, 3, 8]
				]
);


# exponencial

_float(exp($A->get_element(2,2)),2.0085537e1,'plain exp' );

my $B = $A->eval_exp();
_float($B->get_element(0,0), 1, "Exp: Correct value at 0,0");
_float($B->get_element(0,1), 4.4816891, "Exp: Correct value at 0,1");
_float($B->get_element(0,2), 4.5399930e-5, "Exp: Correct value at 0,2");
_float($B->get_element(0,3), 4.034288e2, "Exp: Correct value at 0,3");
_float($B->get_element(1,0), 2.0085537e1, "Exp: Correct value at 1,0");
_float($B->get_element(1,1), 9.4632428e1, "Exp: Correct value at 1,1");
_float($B->get_element(1,2), 2.6912345, "Exp: Correct value at 1,2");
_float($B->get_element(1,3), 1.0966331787e3, "Exp: Correct value at 1,3");
_float($B->get_element(2,0), 1.6487213, "Exp: Correct value at 2,0");
_float($B->get_element(2,1), 3.3546263e-4, "Exp: Correct value at 2,1");
_float($B->get_element(2,2), 2.0085537e1, "Exp: Correct value at 2,2");
_float($B->get_element(2,3), 2.9809580e3, "Exp: Correct value at 2,3");

$B = exp($A);
_float($B->get_element(0,0), 1, "Exp: Correct value at 0,0");
_float($B->get_element(0,1), 4.4816891, "Exp: Correct value at 0,1");
_float($B->get_element(0,2), 4.5399930e-5, "Exp: Correct value at 0,2");
_float($B->get_element(0,3), 4.034288e2, "Exp: Correct value at 0,3");
_float($B->get_element(1,0), 2.0085537e1, "Exp: Correct value at 1,0");
_float($B->get_element(1,1), 9.4632428e1, "Exp: Correct value at 1,1");
_float($B->get_element(1,2), 2.6912345, "Exp: Correct value at 1,2");
_float($B->get_element(1,3), 1.0966331787e3, "Exp: Correct value at 1,3");
_float($B->get_element(2,0), 1.6487213, "Exp: Correct value at 2,0");
_float($B->get_element(2,1), 3.3546263e-4, "Exp: Correct value at 2,1");
_float($B->get_element(2,2), 2.0085537e1, "Exp: Correct value at 2,2");
_float($B->get_element(2,3), 2.9809580e3, "Exp: Correct value at 2,3");


# log
_float(log($M->get_element(1,2)), -1.0050336e-2, "Right plain log");

my $C = $M->eval_log();
_float($C->get_element(0,0), -1.2039728, "Log: Correct value at 0,0");
_float($C->get_element(0,1), 4.0546511e-1, "Log: Correct value at 0,1");
_float($C->get_element(0,2), 2.3025851, "Log: Correct value at 0,2");
_float($C->get_element(0,3), 1.7917595, "Log: Correct value at 0,3");
_float($C->get_element(1,0), 1.0986123, "Log: Correct value at 1,0");
_float($C->get_element(1,1), 1.5151272, "Log: Correct value at 1,1");
_float($C->get_element(1,2), -1.0050336e-2, "Log: Correct value at 1,2");
_float($C->get_element(1,3), 1.9459101, "Log: Correct value at 1,3");
_float($C->get_element(2,0), -6.9314718e-1, "Log: Correct value at 2,0");
_float($C->get_element(2,1), -6.9077553, "Log: Correct value at 2,1");
_float($C->get_element(2,2), 1.0986123, "Log: Correct value at 2,2");
_float($C->get_element(2,3), 2.0794415, "Log: Correct value at 2,3");

$C = log($M);
_float($C->get_element(0,0), -1.2039728, "Log: Correct value at 0,0");
_float($C->get_element(0,1), 4.0546511e-1, "Log: Correct value at 0,1");
_float($C->get_element(0,2), 2.3025851, "Log: Correct value at 0,2");
_float($C->get_element(0,3), 1.7917595, "Log: Correct value at 0,3");
_float($C->get_element(1,0), 1.0986123, "Log: Correct value at 1,0");
_float($C->get_element(1,1), 1.5151272, "Log: Correct value at 1,1");
_float($C->get_element(1,2), -1.0050336e-2, "Log: Correct value at 1,2");
_float($C->get_element(1,3), 1.9459101, "Log: Correct value at 1,3");
_float($C->get_element(2,0), -6.9314718e-1, "Log: Correct value at 2,0");
_float($C->get_element(2,1), -6.9077553, "Log: Correct value at 2,1");
_float($C->get_element(2,2), 1.0986123, "Log: Correct value at 2,2");
_float($C->get_element(2,3), 2.0794415, "Log: Correct value at 2,3");


# Pow
_float( $M->get_element(1,1)**2, 2.07025e1, "Right plain pow"); 

my $D = $M->eval_pow(2);
_float($D->get_element(0,0), 9e-2, "Log: Correct value at 0,0");
_float($D->get_element(0,1), 2.25, "Log: Correct value at 0,1");
_float($D->get_element(0,2), 1e2, "Log: Correct value at 0,2");
_float($D->get_element(0,3), 3.6e1, "Log: Correct value at 0,3");
_float($D->get_element(1,0), 9, "Log: Correct value at 1,0");
_float($D->get_element(1,1), 2.07025e1, "Log: Correct value at 1,1");
_float($D->get_element(1,2), 9.801e-1, "Log: Correct value at 1,2");
_float($D->get_element(1,3), 4.9e1, "Log: Correct value at 1,3");
_float($D->get_element(2,0), 2.5e-1, "Log: Correct value at 2,0");
_float($D->get_element(2,1), 1e-6, "Log: Correct value at 2,1");
_float($D->get_element(2,2), 9, "Log: Correct value at 2,2");
_float($D->get_element(2,3), 6.4e1, "Log: Correct value at 2,3");


$D = $M ** 2;
_float($D->get_element(0,0), 9e-2, "Log: Correct value at 0,0");
_float($D->get_element(0,1), 2.25, "Log: Correct value at 0,1");
_float($D->get_element(0,2), 1e2, "Log: Correct value at 0,2");
_float($D->get_element(0,3), 3.6e1, "Log: Correct value at 0,3");
_float($D->get_element(1,0), 9, "Log: Correct value at 1,0");
_float($D->get_element(1,1), 2.07025e1, "Log: Correct value at 1,1");
_float($D->get_element(1,2), 9.801e-1, "Log: Correct value at 1,2");
_float($D->get_element(1,3), 4.9e1, "Log: Correct value at 1,3");
_float($D->get_element(2,0), 2.5e-1, "Log: Correct value at 2,0");
_float($D->get_element(2,1), 1e-6, "Log: Correct value at 2,1");
_float($D->get_element(2,2), 9, "Log: Correct value at 2,2");
_float($D->get_element(2,3), 6.4e1, "Log: Correct value at 2,3");



# log
_float(log(2), 0.693147, 'plain log');
my $n = log(Math::Lapack::Matrix->new( [ [2,3] ] ));
_float($n->get_element(0,0), 0.693147 , "elementwise log");
_float($n->get_element(0,1), 1.098612, "elementwise log");
#multiply element-wise
my $e = Math::Lapack::Matrix->new([ [0], [3] ]);
isa_ok $e, ['Math::Lapack::Matrix'], "New returned a matrix E";

# Pow

done_testing;


sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.00001), $c);
}
