use strict;
use Math::Complex;
use Math::Symbolic qw/:all/;
use Math::Symbolic::Custom::Collect;

use Test::Simple 'no_plan';

# some constant complex arithmetic expressions
my %tests_1 = (
    "complex test 01"           =>      { Expr => 'sqrt(-64)', Ans => cplx(0,8), },
    #"complex test 02"           =>      { Expr => 'sqrt(-7)', Ans => cplx(0,sqrt(7)), },
    "complex test 03"           =>      { Expr => 'sqrt(16)-sqrt(-81)', Ans => cplx(4,-9), },
    "complex test 04"           =>      { Expr => '3-sqrt(-25)', Ans => cplx(3,-5), },
    "complex test 05"           =>      { Expr => 'sqrt(-100)-sqrt(-49)', Ans => cplx(0,3), },
    "complex test 06"           =>      { Expr => '(2+3*i)+(4-7*i)', Ans => cplx(6,-4), },
    "complex test 07"           =>      { Expr => '(-3+5*i)+(-6-7*i)', Ans => cplx(-9,-2), },
    "complex test 08"           =>      { Expr => '(-7-10*i)+(2-3*i)', Ans => cplx(-5,-13), },
    "complex test 09"           =>      { Expr => '(2+4*i)-(3-6*i)', Ans => cplx(-1,10), },
    "complex test 10"           =>      { Expr => '(-3+5*i)-(-7+4*i)', Ans => cplx(4,1), },
    "complex test 11"           =>      { Expr => '(-9-6*i)-(-8-9*i)', Ans => cplx(-1,3), },
    "complex test 12"           =>      { Expr => '(6-3*i)-(8-5*i)', Ans => cplx(-2,2), },
    "complex test 13"           =>      { Expr => '(2+i)*(3-i)', Ans => cplx(7,1), },
    "complex test 14"           =>      { Expr => '(-3-4*i)*(2-7*i)', Ans => cplx(-34,13), },
    "complex test 15"           =>      { Expr => '(5+2*i)*(-3+4*i)', Ans => cplx(-23,14), },
    "complex test 16"           =>      { Expr => '(1-5*i)^2', Ans => cplx(-24,-10), },
    "complex test 17"           =>      { Expr => '(2-i)^3', Ans => cplx(2,-11), },
    "complex test 18"           =>      { Expr => '(1+i)*(2-i)*(i+3)', Ans => cplx(8,6), },
    "complex test 19"           =>      { Expr => 'i*(3-7*i)*(2-i)', Ans => cplx(17,-1), },
    "complex test 20"           =>      { Expr => 'i^3', Ans => cplx(0,-1), },
    "complex test 21"           =>      { Expr => 'i^7', Ans => cplx(0,-1), },
    "complex test 22"           =>      { Expr => 'i^-9', Ans => cplx(0,-1), },
    "complex test 23"           =>      { Expr => 'i*(2*i-3*i^3)', Ans => cplx(-5,0), },
    "complex test 24"           =>      { Expr => '(i+2*i^2)*(3-i)', Ans => cplx(-5,5), },
    "complex test 25"           =>      { Expr => '2*i*(5-2*i)', Ans => cplx(4,10), },
    "complex test 26"           =>      { Expr => '(2+i)^2', Ans => cplx(3,4), },
    "complex test 27"           =>      { Expr => '(4-i)^5', Ans => cplx(404,-1121), },    
    "complex test 28"           =>      { Expr => '(1+2*i)^2 + (3-i)^3', Ans => cplx(15,-22), },
    "complex test 29"           =>      { Expr => '(1+i)^2 - 3*(2-i)^3', Ans => cplx(-6,35), },
);

while ( my ($t, $d) = each %tests_1 ) {
    my $e = parse_from_string($d->{Expr});
    my $tc = $e->to_collected(); 
    my $v = $tc->value( 'i' => i );
    ok( $v == $d->{Ans}, $t );    
}

# symbolic_complex
my %tests_2 = (
    "symbolic_complex test 01"   =>      { Re => 1,     Im => 2,        Ans => cplx(1, 2),      Vals => {} },
    "symbolic_complex test 02"   =>      { Re => 2,     Im => 1,        Ans => cplx(2, 1),      Vals => {} },
    "symbolic_complex test 03"   =>      { Re => 1,     Im => -2,       Ans => cplx(1, -2),     Vals => {} },
    "symbolic_complex test 04"   =>      { Re => 2,     Im => -1,       Ans => cplx(2, -1),     Vals => {} },
    "symbolic_complex test 05"   =>      { Re => -1,    Im => 2,        Ans => cplx(-1, 2),     Vals => {} },
    "symbolic_complex test 06"   =>      { Re => -2,    Im => 1,        Ans => cplx(-2, 1),     Vals => {} },
    "symbolic_complex test 07"   =>      { Re => -1,    Im => -2,       Ans => cplx(-1, -2),    Vals => {} },
    "symbolic_complex test 08"   =>      { Re => -2,    Im => -1,       Ans => cplx(-2, -1),    Vals => {} },
    "symbolic_complex test 09"   =>      { Re => 'x',   Im => 'y',      Ans => cplx(1, 2),      Vals => { 'x' => 1, 'y' => 2 } },
    "symbolic_complex test 10"   =>      { Re => '5-x', Im => 2,        Ans => cplx(1, 2),      Vals => { 'x' => 4 } },
    "symbolic_complex test 11"   =>      { Re => '5-x', Im => 'y+2',    Ans => cplx(1, 2),      Vals => { 'x' => 4, 'y' => 0 } },
    "symbolic_complex test 12"   =>      { Re => '5-x', Im => 'y+2',    Ans => cplx(1, 5),      Vals => { 'x' => 4, 'y' => 3 } },
    "symbolic_complex test 13"   =>      { Re => 0,     Im => 2,        Ans => cplx(0, 2),      Vals => {} },
    "symbolic_complex test 14"   =>      { Re => 1,     Im => 0,        Ans => cplx(1, 0),      Vals => {} },
);

while ( my ($t, $d) = each %tests_2 ) {

    my $e = symbolic_complex($d->{Re}, $d->{Im});
    my $v = $e->value( 'i' => i, %{$d->{Vals}} );
    ok( $v == $d->{Ans}, $t );    
}

# test_complex
my %tests_3 = (
    "test_complex test 01"  =>      { Expr => '1+2*i',  Re => 1,    Im => 2,    Vals => {} },
    "test_complex test 02"  =>      { Expr => '2+i',    Re => 2,    Im => 1,    Vals => {} },    
    "test_complex test 03"  =>      { Expr => '1-2*i',  Re => 1,    Im => -2,   Vals => {} },
    "test_complex test 04"  =>      { Expr => '2-i',    Re => 2,    Im => -1,   Vals => {} },        
    "test_complex test 05"  =>      { Expr => '-1+2*i', Re => -1,   Im => 2,    Vals => {} },
    "test_complex test 06"  =>      { Expr => '-2+i',   Re => -2,   Im => 1,    Vals => {} },    
    "test_complex test 07"  =>      { Expr => '-1-2*i', Re => -1,   Im => -2,   Vals => {} },
    "test_complex test 08"  =>      { Expr => '-2-i',   Re => -2,   Im => -1,   Vals => {} },        
    "test_complex test 09"  =>      { Expr => '1+x*i',  Re => 1,    Im => 2,    Vals => { 'x' => 2 } },
    "test_complex test 10"  =>      { Expr => 'x+2*i',  Re => 1,    Im => 2,    Vals => { 'x' => 1 } },    
    "test_complex test 11"  =>      { Expr => '5*y + sqrt(-100) + x*i', Re => 10, Im => 11, Vals => { 'x' => 1, 'y' => 2 } },
    "test_complex test 12"  =>      { Expr => 'x^2 + 3 + 5*i + sqrt(-16)', Re => 12, Im => 9, Vals => { 'x' => 3 } },
    "test_complex test 13"  =>      { Expr => 'sqrt(36)',  Re => 6,    Im => 0,    Vals => {} },
    "test_complex test 14"  =>      { Expr => 'sqrt(-36)',  Re => 0,    Im => 6,    Vals => {} },
);

while ( my ($t, $d) = each %tests_3 ) {
    my $e = parse_from_string($d->{Expr});
    my ($R, $I) = $e->test_complex();
    my $R_v = $R->value(%{$d->{Vals}});
    my $I_v = $I->value(%{$d->{Vals}});
    ok( ($R_v == $d->{Re}) && ($I_v == $d->{Im}), $t );
}

# to_complex_conjugate
my %tests_4 = (
    "to_complex_conjugate test 01"  =>  { Expr => '2+4*i', Ans => cplx(2,-4), Vals => {}, },
    "to_complex_conjugate test 02"  =>  { Expr => '3-6*i', Ans => cplx(3,6), Vals => {}, },
    "to_complex_conjugate test 03"  =>  { Expr => '-5+2*i', Ans => cplx(-5,-2), Vals => {}, },
    "to_complex_conjugate test 04"  =>  { Expr => '-7-3*i', Ans => cplx(-7,3), Vals => {}, },
    "to_complex_conjugate test 05"  =>  { Expr => '2*i-4', Ans => cplx(-4,-2), Vals => {}, },
    "to_complex_conjugate test 06"  =>  { Expr => '6', Ans => cplx(6,0), Vals => {}, },
    "to_complex_conjugate test 07"  =>  { Expr => '3*i', Ans => cplx(0,-3), Vals => {}, },
    "to_complex_conjugate test 08"  =>  { Expr => '-3*i+7', Ans => cplx(7,3), Vals => {}, },
    "to_complex_conjugate test 09"  =>  { Expr => 'x+y*i', Ans => cplx(1, -1), Vals => { 'x' => 1, 'y' => 1 }, },
    "to_complex_conjugate test 10"  =>  { Expr => 'x+y*i', Ans => cplx(1, 1), Vals => { 'x' => 1, 'y' => -1 }, },
);

while ( my ($t, $d) = each %tests_4 ) {
    my $e = parse_from_string($d->{Expr});
    my $v = $e->to_complex_conjugate()->value( 'i' => i, %{$d->{Vals}} );
    ok( $v == $d->{Ans}, $t );    
}


