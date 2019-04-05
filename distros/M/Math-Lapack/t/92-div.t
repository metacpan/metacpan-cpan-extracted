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
				[ [ 1, 70, 0.002 ], 
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

my $E = $A->eval_div($B);

isa_ok $E, ['Math::Lapack::Matrix'], "E returned a matrix";

_float($E->get_element(0,0), 7, 		"Element correct at 0,0");
_float($E->get_element(0,1), 1.4286e-1, "Element correct at 0,1");
_float($E->get_element(0,2), 1e4, 	"Element correct at 0,2");
_float($E->get_element(1,0), -5.8834e-1, 		"Element correct at 1,0");
_float($E->get_element(1,1), -2.2135, 	"Element correct at 1,1");
_float($E->get_element(1,2), -3.003, 	"Element correct at 1,2");
_float($E->get_element(2,0), -5, 		"Element correct at 1,0");
_float($E->get_element(2,1), -9.0866e-1, "Element correct at 2,1");
_float($E->get_element(2,2), -5.0804, "Element correct at 2,2");

# Division with '/' overloading
$E = $A / $B;

_float($E->get_element(0,0), 7, 		"Element correct at 0,0");
_float($E->get_element(0,1), 1.4286e-1, "Element correct at 0,1");
_float($E->get_element(0,2), 1e4, 	"Element correct at 0,2");
_float($E->get_element(1,0), -5.8834e-1, 		"Element correct at 1,0");
_float($E->get_element(1,1), -2.2135, 	"Element correct at 1,1");
_float($E->get_element(1,2), -3.003, 	"Element correct at 1,2");
_float($E->get_element(2,0), -5, 		"Element correct at 1,0");
_float($E->get_element(2,1), -9.0866e-1, "Element correct at 2,1");
_float($E->get_element(2,2), -5.0804, "Element correct at 2,2");


# Division with vertical broadcasting
my $F = $A->eval_div($D);

isa_ok $F, ['Math::Lapack::Matrix'], "F returned a matrix";

_float($F->get_element(0,0), -.29167, 		"Element correct at 0,0");
_float($F->get_element(0,1), -.41667, "Element correct at 0,1");
_float($F->get_element(0,2), -.83333, 	"Element correct at 0,2");
_float($F->get_element(1,0), 1.9988, 		"Element correct at 1,0");
_float($F->get_element(1,1), -11.82473, 	"Element correct at 1,1");
_float($F->get_element(1,2), -6.00240, 	"Element correct at 1,2");
_float($F->get_element(2,0), -6.12245, 		"Element correct at 1,0");
_float($F->get_element(2,1), -3.12653, "Element correct at 2,1");
_float($F->get_element(2,2), -4.12653, "Element correct at 2,2");


# Division with '/' overloading and vertical broadcasting
$F = $A / $D;

_float($F->get_element(0,0), -.29167, 		"Element correct at 0,0");
_float($F->get_element(0,1), -.41667, "Element correct at 0,1");
_float($F->get_element(0,2), -.83333, 	"Element correct at 0,2");
_float($F->get_element(1,0), 1.9988, 		"Element correct at 1,0");
_float($F->get_element(1,1), -11.82473, 	"Element correct at 1,1");
_float($F->get_element(1,2), -6.00240, 	"Element correct at 1,2");
_float($F->get_element(2,0), -6.12245, 		"Element correct at 1,0");
_float($F->get_element(2,1), -3.12653, "Element correct at 2,1");
_float($F->get_element(2,2), -4.12653, "Element correct at 2,2");


# Division with '/' overloading and vertical broadcasting with reverse order
$F = $D / $A;

_float($F->get_element(0,0), -3.428571, 		"Element correct at 0,0");
_float($F->get_element(0,1), -2.4, "Element correct at 0,1");
_float($F->get_element(0,2), -1.2, 	"Element correct at 0,2");
_float($F->get_element(1,0), 0.5003, 		"Element correct at 1,0");
_float($F->get_element(1,1), -.084569, 	"Element correct at 1,1");
_float($F->get_element(1,2), -.1666, 	"Element correct at 1,2");
_float($F->get_element(2,0), -.163333, 		"Element correct at 1,0");
_float($F->get_element(2,1), -.319843, "Element correct at 2,1");
_float($F->get_element(2,2), -.242334, "Element correct at 2,2");


# Division with horizontal broadcasting
my $G = $B->eval_div($C);

isa_ok $G, ['Math::Lapack::Matrix'], "G returned a matrix";

_float($G->get_element(0,0), 6.6667e-2, 		"Element correct at 0,0");
_float($G->get_element(0,1), -3.5e1, "Element correct at 0,1");
_float($G->get_element(0,2), -4e-5, 	"Element correct at 0,2");
_float($G->get_element(1,0), -3.7733e-1, 		"Element correct at 1,0");
_float($G->get_element(1,1), -4.45, 	"Element correct at 1,1");
_float($G->get_element(1,2), -6.66e-2, 	"Element correct at 1,2");
_float($G->get_element(2,0), 2e-1, 		"Element correct at 1,0");
_float($G->get_element(2,1), -4.215, "Element correct at 2,1");
_float($G->get_element(2,2), -3.98e-2, "Element correct at 2,2");


# Division with '/' overloading and horizontal broadcasting
$G = $B / $C;

_float($G->get_element(0,0), 6.6667e-2, 		"Element correct at 0,0");
_float($G->get_element(0,1), -3.5e1, "Element correct at 0,1");
_float($G->get_element(0,2), -4e-5, 	"Element correct at 0,2");
_float($G->get_element(1,0), -3.7733e-1, 		"Element correct at 1,0");
_float($G->get_element(1,1), -4.45, 	"Element correct at 1,1");
_float($G->get_element(1,2), -6.66e-2, 	"Element correct at 1,2");
_float($G->get_element(2,0), 2e-1, 		"Element correct at 1,0");
_float($G->get_element(2,1), -4.215, "Element correct at 2,1");
_float($G->get_element(2,2), -3.98e-2, "Element correct at 2,2");


# Division with '/' overloading and horizontal broadcasting with reverse order
$G = $C / $B;

_float($G->get_element(0,0), 1.5e1, 		"Element correct at 0,0");
_float($G->get_element(0,1), -2.8571e-2, "Element correct at 0,1");
_float($G->get_element(0,2), -2.4999998e4, 	"Element correct at 0,2");
_float($G->get_element(1,0), -2.6502, 		"Element correct at 1,0");
_float($G->get_element(1,1), -2.2472e-1, 	"Element correct at 1,1");
_float($G->get_element(1,2), -1.5015e1, 	"Element correct at 1,2");
_float($G->get_element(2,0), 5, 		"Element correct at 1,0");
_float($G->get_element(2,1), -2.3725e-1, "Element correct at 2,1");
_float($G->get_element(2,2), -2.5126e1, "Element correct at 2,2");

# Division element-wise with '/' overloading

my $H = $A / 5.123;

_float($H->get_element(0,0), 1.3663869, 		"Element correct at 0,0");
_float($H->get_element(0,1), 1.9519813, "Element correct at 0,1");
_float($H->get_element(0,2), 3.9039625, 	"Element correct at 0,2");
_float($H->get_element(1,0), 6.5000976e-1, 		"Element correct at 1,0");
_float($H->get_element(1,1), -3.8454031, 	"Element correct at 1,1");
_float($H->get_element(1,2), -1.9519813, 	"Element correct at 1,2");
_float($H->get_element(2,0), -2.9279719, 		"Element correct at 1,0");
_float($H->get_element(2,1), -1.4952176, "Element correct at 2,1");
_float($H->get_element(2,2), -1.9734531, "Element correct at 2,2");

$H = 5.123 / $A;

_float($H->get_element(0,0), 7.31857143e-1, 		"Element correct at 0,0");
_float($H->get_element(0,1), 5.123e-1, "Element correct at 0,1");
_float($H->get_element(0,2), 2.5615e-1, 	"Element correct at 0,2");
_float($H->get_element(1,0), 1.53843844, 		"Element correct at 1,0");
_float($H->get_element(1,1), -2.60050761e-1, 	"Element correct at 1,1");
_float($H->get_element(1,2), -5.123e-1, 	"Element correct at 1,2");
_float($H->get_element(2,0), -3.41533333e-1, 		"Element correct at 1,0");
_float($H->get_element(2,1), -6.68798956e-1, "Element correct at 2,1");
_float($H->get_element(2,2), -5.06726014e-01, "Element correct at 2,2");


done_testing;

sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.001), $c);
}

