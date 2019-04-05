#!perl

use Test2::V0;
use Math::Lapack::Matrix;


my $A = Math::Lapack::Matrix->new(
				[ [ 7, 10, 20 ], 
					[ 3.33, -19.7, -10 ],
					[ -15, -7.66, -10.11 ]	
				]
);


my $B = Math::Lapack::Matrix->new(
				[ [ 1, 70, .002 ], 
					[ -5.660, 8.90, 3.330 ],
					[ 3, 8.430, 1.990 ]	
				]
);

my $C = Math::Lapack::Matrix->new( [ [15, -2, -50] ] );

my $D = Math::Lapack::Matrix->new( 
				[ [ -24], 
					[ 1.6660 ],
					[ 2.450 ]
				] );




isa_ok $A, ['Math::Lapack::Matrix'], "A returned a matrix";
isa_ok $B, ['Math::Lapack::Matrix'], "B returned a matrix";
isa_ok $C, ['Math::Lapack::Matrix'], "C returned a matrix";
isa_ok $D, ['Math::Lapack::Matrix'], "D returned a matrix";

my $E = $A->eval_mul($B);

isa_ok $E, ['Math::Lapack::Matrix'], "E returned a matrix";

_float($E->get_element(0,0), 7, 		"Element correct at 0,0");
_float($E->get_element(0,1), 7e2, "Element correct at 0,1");
_float($E->get_element(0,2), 4e-2, 	"Element correct at 0,2");
_float($E->get_element(1,0), -1.88478e1, 		"Element correct at 1,0");
_float($E->get_element(1,1), -1.7533e2, 	"Element correct at 1,1");
_float($E->get_element(1,2), -3.33e1, 	"Element correct at 1,2");
_float($E->get_element(2,0), -4.5e1, 		"Element correct at 1,0");
_float($E->get_element(2,1), -6.45738e1, "Element correct at 2,1");
_float($E->get_element(2,2), -2.01189e1, "Element correct at 2,2");

#Multiplication with '*' overloading
$E = $A * $B;

_float($E->get_element(0,0), 7, 		"Element correct at 0,0");
_float($E->get_element(0,1), 7e2, "Element correct at 0,1");
_float($E->get_element(0,2), 4e-2, 	"Element correct at 0,2");
_float($E->get_element(1,0), -1.88478e1, 		"Element correct at 1,0");
_float($E->get_element(1,1), -1.7533e2, 	"Element correct at 1,1");
_float($E->get_element(1,2), -3.33e1, 	"Element correct at 1,2");
_float($E->get_element(2,0), -4.5e1, 		"Element correct at 1,0");
_float($E->get_element(2,1), -6.45738e1, "Element correct at 2,1");
_float($E->get_element(2,2), -2.01189e1, "Element correct at 2,2");


# Multiplication with vertical broadcasting
my $F = $A->eval_mul($D);

isa_ok $F, ['Math::Lapack::Matrix'], "F returned a matrix";

_float($F->get_element(0,0), -168, 		"Element correct at 0,0");
_float($F->get_element(0,1), -240, "Element correct at 0,1");
_float($F->get_element(0,2), -480, 	"Element correct at 0,2");
_float($F->get_element(1,0), 5.54778, 		"Element correct at 1,0");
_float($F->get_element(1,1), -32.8202, 	"Element correct at 1,1");
_float($F->get_element(1,2), -16.66, 	"Element correct at 1,2");
_float($F->get_element(2,0), -36.75, 		"Element correct at 1,0");
_float($F->get_element(2,1), -18.767, "Element correct at 2,1");
_float($F->get_element(2,2), -24.7695, "Element correct at 2,2");


# Multiplication with '*' overloading and vertical broadcasting
$F = $A * $D;

_float($F->get_element(0,0), -168, 		"Element correct at 0,0");
_float($F->get_element(0,1), -240, "Element correct at 0,1");
_float($F->get_element(0,2), -480, 	"Element correct at 0,2");
_float($F->get_element(1,0), 5.54778, 		"Element correct at 1,0");
_float($F->get_element(1,1), -32.8202, 	"Element correct at 1,1");
_float($F->get_element(1,2), -16.66, 	"Element correct at 1,2");
_float($F->get_element(2,0), -36.75, 		"Element correct at 1,0");
_float($F->get_element(2,1), -18.767, "Element correct at 2,1");
_float($F->get_element(2,2), -24.7695, "Element correct at 2,2");


# Multiplication with '*' overloading and vertical broadcasting with reverse order
$F = $D * $A;

_float($F->get_element(0,0), -168, 		"Element correct at 0,0");
_float($F->get_element(0,1), -240, "Element correct at 0,1");
_float($F->get_element(0,2), -480, 	"Element correct at 0,2");
_float($F->get_element(1,0), 5.54778, 		"Element correct at 1,0");
_float($F->get_element(1,1), -32.8202, 	"Element correct at 1,1");
_float($F->get_element(1,2), -16.66, 	"Element correct at 1,2");
_float($F->get_element(2,0), -36.75, 		"Element correct at 1,0");
_float($F->get_element(2,1), -18.767, "Element correct at 2,1");
_float($F->get_element(2,2), -24.7695, "Element correct at 2,2");


# Multiplication with horizontal broadcasting
my $G = $B->eval_mul($C);

isa_ok $G, ['Math::Lapack::Matrix'], "G returned a matrix";

_float($G->get_element(0,0), 15, 		"Element correct at 0,0");
_float($G->get_element(0,1), -140, "Element correct at 0,1");
_float($G->get_element(0,2), -.1, 	"Element correct at 0,2");
_float($G->get_element(1,0), -84.9, 		"Element correct at 1,0");
_float($G->get_element(1,1), -17.8, 	"Element correct at 1,1");
_float($G->get_element(1,2), -166.5, 	"Element correct at 1,2");
_float($G->get_element(2,0), 45, 		"Element correct at 1,0");
_float($G->get_element(2,1), -16.86, "Element correct at 2,1");
_float($G->get_element(2,2), -99.5, "Element correct at 2,2");


# Multiplication with '*' overloading and horizontal broadcasting
$G = $B * $C;

_float($G->get_element(0,0), 15, 		"Element correct at 0,0");
_float($G->get_element(0,1), -140, "Element correct at 0,1");
_float($G->get_element(0,2), -.1, 	"Element correct at 0,2");
_float($G->get_element(1,0), -84.9, 		"Element correct at 1,0");
_float($G->get_element(1,1), -17.8, 	"Element correct at 1,1");
_float($G->get_element(1,2), -166.5, 	"Element correct at 1,2");
_float($G->get_element(2,0), 45, 		"Element correct at 1,0");
_float($G->get_element(2,1), -16.86, "Element correct at 2,1");
_float($G->get_element(2,2), -99.5, "Element correct at 2,2");


# Multiplication with '*' overloading and horizontal broadcasting with reverse order
$G = $C * $B;

_float($G->get_element(0,0), 15, 		"Element correct at 0,0");
_float($G->get_element(0,1), -140, "Element correct at 0,1");
_float($G->get_element(0,2), -.1, 	"Element correct at 0,2");
_float($G->get_element(1,0), -84.9, 		"Element correct at 1,0");
_float($G->get_element(1,1), -17.8, 	"Element correct at 1,1");
_float($G->get_element(1,2), -166.5, 	"Element correct at 1,2");
_float($G->get_element(2,0), 45, 		"Element correct at 1,0");
_float($G->get_element(2,1), -16.86, "Element correct at 2,1");
_float($G->get_element(2,2), -99.5, "Element correct at 2,2");

# Multiplication element-wise with '*' overloading
my $H = $A * 4;

_float($H->get_element(0,0), 28, 		"Element correct at 0,0");
_float($H->get_element(0,1), 40, "Element correct at 0,1");
_float($H->get_element(0,2), 80, 	"Element correct at 0,2");
_float($H->get_element(1,0), 13.32, 		"Element correct at 1,0");
_float($H->get_element(1,1), -78.8, 	"Element correct at 1,1");
_float($H->get_element(1,2), -40, 	"Element correct at 1,2");
_float($H->get_element(2,0), -60, 		"Element correct at 1,0");
_float($H->get_element(2,1), -30.64, "Element correct at 2,1");
_float($H->get_element(2,2), -40.44, "Element correct at 2,2");

$H = 4 * $A;

_float($H->get_element(0,0), 28, 		"Element correct at 0,0");
_float($H->get_element(0,1), 40, "Element correct at 0,1");
_float($H->get_element(0,2), 80, 	"Element correct at 0,2");
_float($H->get_element(1,0), 13.32, 		"Element correct at 1,0");
_float($H->get_element(1,1), -78.8, 	"Element correct at 1,1");
_float($H->get_element(1,2), -40, 	"Element correct at 1,2");
_float($H->get_element(2,0), -60, 		"Element correct at 1,0");
_float($H->get_element(2,1), -30.64, "Element correct at 2,1");
_float($H->get_element(2,2), -40.44, "Element correct at 2,2");




done_testing;

sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.00001), $c);
}

