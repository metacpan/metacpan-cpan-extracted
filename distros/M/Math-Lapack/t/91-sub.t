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

my $E = $A->eval_sub($B);

isa_ok $E, ['Math::Lapack::Matrix'], "E returned a matrix";

_float($E->get_element(0,0), 6, 		"Element correct at 0,0");
_float($E->get_element(0,1), -60, "Element correct at 0,1");
_float($E->get_element(0,2), 20, 	"Element correct at 0,2");
_float($E->get_element(1,0), 8.99, 		"Element correct at 1,0");
_float($E->get_element(1,1), -28.6, 	"Element correct at 1,1");
_float($E->get_element(1,2), -13.33, 	"Element correct at 1,2");
_float($E->get_element(2,0), -18, 		"Element correct at 1,0");
_float($E->get_element(2,1), -16.09, "Element correct at 2,1");
_float($E->get_element(2,2), -12.1, "Element correct at 2,2");

# Subtraction with '-' overloading
$E = $A - $B;

_float($E->get_element(0,0), 6, 		"Element correct at 0,0");
_float($E->get_element(0,1), -60, "Element correct at 0,1");
_float($E->get_element(0,2), 20, 	"Element correct at 0,2");
_float($E->get_element(1,0), 8.99, 		"Element correct at 1,0");
_float($E->get_element(1,1), -28.6, 	"Element correct at 1,1");
_float($E->get_element(1,2), -13.33, 	"Element correct at 1,2");
_float($E->get_element(2,0), -18, 		"Element correct at 1,0");
_float($E->get_element(2,1), -16.09, "Element correct at 2,1");
_float($E->get_element(2,2), -12.1, "Element correct at 2,2");


# Subtraction with vertical broadcasting
my $F = $A->eval_sub($D);

isa_ok $F, ['Math::Lapack::Matrix'], "F returned a matrix";

_float($F->get_element(0,0), 31, 		"Element correct at 0,0");
_float($F->get_element(0,1), 34, "Element correct at 0,1");
_float($F->get_element(0,2), 44, 	"Element correct at 0,2");
_float($F->get_element(1,0), 1.664, 		"Element correct at 1,0");
_float($F->get_element(1,1), -21.366, 	"Element correct at 1,1");
_float($F->get_element(1,2), -11.666, 	"Element correct at 1,2");
_float($F->get_element(2,0), -17.45, 		"Element correct at 1,0");
_float($F->get_element(2,1), -10.11, "Element correct at 2,1");
_float($F->get_element(2,2), -12.56, "Element correct at 2,2");


# Subtraction with '-' overloading and vertical broadcasting
$F = $A - $D;

_float($F->get_element(0,0), 31, 		"Element correct at 0,0");
_float($F->get_element(0,1), 34, "Element correct at 0,1");
_float($F->get_element(0,2), 44, 	"Element correct at 0,2");
_float($F->get_element(1,0), 1.664, 		"Element correct at 1,0");
_float($F->get_element(1,1), -21.366, 	"Element correct at 1,1");
_float($F->get_element(1,2), -11.666, 	"Element correct at 1,2");
_float($F->get_element(2,0), -17.45, 		"Element correct at 1,0");
_float($F->get_element(2,1), -10.11, "Element correct at 2,1");
_float($F->get_element(2,2), -12.56, "Element correct at 2,2");

# Subtraction with '-' overloading and vertical broadcasting with reverse order
$F = $D - $A;

_float($F->get_element(0,0), -31, 		"Element correct at 0,0");
_float($F->get_element(0,1), -34, "Element correct at 0,1");
_float($F->get_element(0,2), -44, 	"Element correct at 0,2");
_float($F->get_element(1,0), -1.664, 		"Element correct at 1,0");
_float($F->get_element(1,1), 21.366, 	"Element correct at 1,1");
_float($F->get_element(1,2), 11.666, 	"Element correct at 1,2");
_float($F->get_element(2,0), 17.45, 		"Element correct at 1,0");
_float($F->get_element(2,1), 10.11, "Element correct at 2,1");
_float($F->get_element(2,2), 12.56, "Element correct at 2,2");


# Subtraction with horizontal broadcasting
my $G = $B->eval_sub($C);

isa_ok $G, ['Math::Lapack::Matrix'], "G returned a matrix";

_float($G->get_element(0,0), -14, 		"Element correct at 0,0");
_float($G->get_element(0,1), 72, "Element correct at 0,1");
_float($G->get_element(0,2), 50, 	"Element correct at 0,2");
_float($G->get_element(1,0), -20.66, 		"Element correct at 1,0");
_float($G->get_element(1,1), 10.9, 	"Element correct at 1,1");
_float($G->get_element(1,2), 53.33, 	"Element correct at 1,2");
_float($G->get_element(2,0), -12, 		"Element correct at 1,0");
_float($G->get_element(2,1), 10.43, "Element correct at 2,1");
_float($G->get_element(2,2), 51.99, "Element correct at 2,2");


# Subtraction with '-' overloading and horizontal broadcasting
$G = $B - $C;

_float($G->get_element(0,0), -14, 		"Element correct at 0,0");
_float($G->get_element(0,1), 72, "Element correct at 0,1");
_float($G->get_element(0,2), 50, 	"Element correct at 0,2");
_float($G->get_element(1,0), -20.66, 		"Element correct at 1,0");
_float($G->get_element(1,1), 10.9, 	"Element correct at 1,1");
_float($G->get_element(1,2), 53.33, 	"Element correct at 1,2");
_float($G->get_element(2,0), -12, 		"Element correct at 1,0");
_float($G->get_element(2,1), 10.43, "Element correct at 2,1");
_float($G->get_element(2,2), 51.99, "Element correct at 2,2");


# Add with '-' overloading and horizontal broadcasting with reverse order
$G = $C - $B;

_float($G->get_element(0,0), 14, 		"Element correct at 0,0");
_float($G->get_element(0,1), -72, "Element correct at 0,1");
_float($G->get_element(0,2), -50, 	"Element correct at 0,2");
_float($G->get_element(1,0), 20.66, 		"Element correct at 1,0");
_float($G->get_element(1,1), -10.9, 	"Element correct at 1,1");
_float($G->get_element(1,2), -53.33, 	"Element correct at 1,2");
_float($G->get_element(2,0), 12, 		"Element correct at 1,0");
_float($G->get_element(2,1), -10.43, "Element correct at 2,1");
_float($G->get_element(2,2), -51.99, "Element correct at 2,2");

my $H = $A - 4.123;

_float($H->get_element(0,0), 2.877, 		"Element correct at 0,0");
_float($H->get_element(0,1), 5.877, "Element correct at 0,1");
_float($H->get_element(0,2), 15.877, 	"Element correct at 0,2");
_float($H->get_element(1,0), -7.93e-1, 		"Element correct at 1,0");
_float($H->get_element(1,1), -23.823, 	"Element correct at 1,1");
_float($H->get_element(1,2), -14.123, 	"Element correct at 1,2");
_float($H->get_element(2,0), -19.123, 		"Element correct at 1,0");
_float($H->get_element(2,1), -11.783, "Element correct at 2,1");
_float($H->get_element(2,2), -14.233, "Element correct at 2,2");

$H = 4.123 - $A;

_float($H->get_element(0,0), -2.877, 		"Element correct at 0,0");
_float($H->get_element(0,1), -5.877, "Element correct at 0,1");
_float($H->get_element(0,2), -15.877, 	"Element correct at 0,2");
_float($H->get_element(1,0), 7.93e-1, 		"Element correct at 1,0");
_float($H->get_element(1,1), 23.823, 	"Element correct at 1,1");
_float($H->get_element(1,2), 14.123, 	"Element correct at 1,2");
_float($H->get_element(2,0), 19.123, 		"Element correct at 1,0");
_float($H->get_element(2,1), 11.783, "Element correct at 2,1");
_float($H->get_element(2,2), 14.233, "Element correct at 2,2");

done_testing;

sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.00001), $c);
}

