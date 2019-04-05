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
				[ [ 1, 70, 0 ], 
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

my $E = $A->eval_add($B);

isa_ok $E, ['Math::Lapack::Matrix'], "E returned a matrix";

_float($E->get_element(0,0), 8, 		"Element correct at 0,0");
_float($E->get_element(0,1), 80, "Element correct at 0,1");
_float($E->get_element(0,2), 20, 	"Element correct at 0,2");
_float($E->get_element(1,0), -2.33, 		"Element correct at 1,0");
_float($E->get_element(1,1), -10.8, 	"Element correct at 1,1");
_float($E->get_element(1,2), -6.67, 	"Element correct at 1,2");
_float($E->get_element(2,0), -12, 		"Element correct at 1,0");
_float($E->get_element(2,1), 0.77, "Element correct at 2,1");
_float($E->get_element(2,2), -8.12, "Element correct at 2,2");

#Add with '+' overloading
$E = $A + $B;

_float($E->get_element(0,0), 8, 		"Element correct at 0,0");
_float($E->get_element(0,1), 80, "Element correct at 0,1");
_float($E->get_element(0,2), 20, 	"Element correct at 0,2");
_float($E->get_element(1,0), -2.33, 		"Element correct at 1,0");
_float($E->get_element(1,1), -10.8, 	"Element correct at 1,1");
_float($E->get_element(1,2), -6.67, 	"Element correct at 1,2");
_float($E->get_element(2,0), -12, 		"Element correct at 1,0");
_float($E->get_element(2,1), 0.77, "Element correct at 2,1");
_float($E->get_element(2,2), -8.12, "Element correct at 2,2");


# Add with vertical broadcasting
my $F = $A->eval_add($D);

isa_ok $F, ['Math::Lapack::Matrix'], "F returned a matrix";

_float($F->get_element(0,0), -17, 		"Element correct at 0,0");
_float($F->get_element(0,1), -14, "Element correct at 0,1");
_float($F->get_element(0,2), -4, 	"Element correct at 0,2");
_float($F->get_element(1,0), 4.996, 		"Element correct at 1,0");
_float($F->get_element(1,1), -18.034, 	"Element correct at 1,1");
_float($F->get_element(1,2), -8.334, 	"Element correct at 1,2");
_float($F->get_element(2,0), -12.55, 		"Element correct at 1,0");
_float($F->get_element(2,1), -5.21, "Element correct at 2,1");
_float($F->get_element(2,2), -7.66, "Element correct at 2,2");


# Add with '+' overloading and vertical broadcasting
$F = $A + $D;

_float($F->get_element(0,0), -17, 		"Element correct at 0,0");
_float($F->get_element(0,1), -14, "Element correct at 0,1");
_float($F->get_element(0,2), -4, 	"Element correct at 0,2");
_float($F->get_element(1,0), 4.996, 		"Element correct at 1,0");
_float($F->get_element(1,1), -18.034, 	"Element correct at 1,1");
_float($F->get_element(1,2), -8.334, 	"Element correct at 1,2");
_float($F->get_element(2,0), -12.55, 		"Element correct at 1,0");
_float($F->get_element(2,1), -5.21, "Element correct at 2,1");
_float($F->get_element(2,2), -7.66, "Element correct at 2,2");


# Add with '+' overloading and vertical broadcasting with reverse order
$F = $D + $A;

_float($F->get_element(0,0), -17, 		"Element correct at 0,0");
_float($F->get_element(0,1), -14, "Element correct at 0,1");
_float($F->get_element(0,2), -4, 	"Element correct at 0,2");
_float($F->get_element(1,0), 4.996, 		"Element correct at 1,0");
_float($F->get_element(1,1), -18.034, 	"Element correct at 1,1");
_float($F->get_element(1,2), -8.334, 	"Element correct at 1,2");
_float($F->get_element(2,0), -12.55, 		"Element correct at 1,0");
_float($F->get_element(2,1), -5.21, "Element correct at 2,1");
_float($F->get_element(2,2), -7.66, "Element correct at 2,2");


# Add with horizontal broadcasting
my $G = $B->eval_add($C);

isa_ok $G, ['Math::Lapack::Matrix'], "G returned a matrix";

_float($G->get_element(0,0), 16, 		"Element correct at 0,0");
_float($G->get_element(0,1), 68, "Element correct at 0,1");
_float($G->get_element(0,2), -50, 	"Element correct at 0,2");
_float($G->get_element(1,0), 9.34, 		"Element correct at 1,0");
_float($G->get_element(1,1), 6.9, 	"Element correct at 1,1");
_float($G->get_element(1,2), -46.67, 	"Element correct at 1,2");
_float($G->get_element(2,0), 18, 		"Element correct at 1,0");
_float($G->get_element(2,1), 6.43, "Element correct at 2,1");
_float($G->get_element(2,2), -48.01, "Element correct at 2,2");


# Add with '+' overloading and horizontal broadcasting
$G = $B + $C;

_float($G->get_element(0,0), 16, 		"Element correct at 0,0");
_float($G->get_element(0,1), 68, "Element correct at 0,1");
_float($G->get_element(0,2), -50, 	"Element correct at 0,2");
_float($G->get_element(1,0), 9.34, 		"Element correct at 1,0");
_float($G->get_element(1,1), 6.9, 	"Element correct at 1,1");
_float($G->get_element(1,2), -46.67, 	"Element correct at 1,2");
_float($G->get_element(2,0), 18, 		"Element correct at 1,0");
_float($G->get_element(2,1), 6.43, "Element correct at 2,1");
_float($G->get_element(2,2), -48.01, "Element correct at 2,2");


# Add with '+' overloading and horizontal broadcasting with reverse order
$G = $C + $B;

_float($G->get_element(0,0), 16, 		"Element correct at 0,0");
_float($G->get_element(0,1), 68, "Element correct at 0,1");
_float($G->get_element(0,2), -50, 	"Element correct at 0,2");
_float($G->get_element(1,0), 9.34, 		"Element correct at 1,0");
_float($G->get_element(1,1), 6.9, 	"Element correct at 1,1");
_float($G->get_element(1,2), -46.67, 	"Element correct at 1,2");
_float($G->get_element(2,0), 18, 		"Element correct at 1,0");
_float($G->get_element(2,1), 6.43, "Element correct at 2,1");
_float($G->get_element(2,2), -48.01, "Element correct at 2,2");

# Add element-wise with '+' overloading 
my $H = $A  + 1.33;

_float($H->get_element(0,0), 8.33, 		"Element correct at 0,0");
_float($H->get_element(0,1), 11.33, "Element correct at 0,1");
_float($H->get_element(0,2), 21.33, 	"Element correct at 0,2");
_float($H->get_element(1,0), 4.66, 		"Element correct at 1,0");
_float($H->get_element(1,1), -18.37, 	"Element correct at 1,1");
_float($H->get_element(1,2), -8.67, 	"Element correct at 1,2");
_float($H->get_element(2,0), -13.67, 		"Element correct at 1,0");
_float($H->get_element(2,1), -6.33, "Element correct at 2,1");
_float($H->get_element(2,2), -8.78, "Element correct at 2,2");

$H = 1.33 + $A;

_float($H->get_element(0,0), 8.33, 		"Element correct at 0,0");
_float($H->get_element(0,1), 11.33, "Element correct at 0,1");
_float($H->get_element(0,2), 21.33, 	"Element correct at 0,2");
_float($H->get_element(1,0), 4.66, 		"Element correct at 1,0");
_float($H->get_element(1,1), -18.37, 	"Element correct at 1,1");
_float($H->get_element(1,2), -8.67, 	"Element correct at 1,2");
_float($H->get_element(2,0), -13.67, 		"Element correct at 1,0");
_float($H->get_element(2,1), -6.33, "Element correct at 2,1");
_float($H->get_element(2,2), -8.78, "Element correct at 2,2");

done_testing;

sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.00001), $c);
}

