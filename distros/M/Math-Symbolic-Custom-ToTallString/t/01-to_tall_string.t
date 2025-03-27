use strict;
use Math::Symbolic 0.613 qw(:all);
use Math::Symbolic::Custom::ToTallString 0.1;

use Test::Simple 'no_plan';

my %tests = (
	test_001 => { expr => 'x + 5', output => 'x + 5', height => 1, width => 5 },
	test_002 => { expr => 'x / 5', output => ' x 
---
 5 ', height => 3, width => 3 },
	test_003 => { expr => '4 * (1+2)', output => '4*(1 + 2)', height => 1, width => 9 },
	test_004 => { expr => '5 / (1+2)', output => '   5   
-------
 1 + 2 ', height => 3, width => 7 },
	test_005 => { expr => 'sin(5/8)', output => '   ( 5 )
sin(---)
   ( 8 )', height => 3, width => 8 },
	test_006 => { expr => 'cos(5/8)/100', output => '    ( 5 ) 
 cos(---) 
    ( 8 ) 
----------
   100    ', height => 5, width => 10 },
	test_007 => { expr => 'cos((3/x)/100)', output => '   (  3  )
   ( --- )
cos(  x  )
   (-----)
   ( 100 )', height => 5, width => 10 },
	test_008 => { expr => '(x/(y+1))/(50/(x^2 + 2))', output => '     x     
  -------  
   y + 1   
-----------
    50     
 --------- 
    2      
  x^  + 2  ', height => 8, width => 11 },
	test_009 => { expr => '5 + (1/2)', output => '     1 
5 + ---
     2 ', height => 3, width => 7 },
	test_010 => { expr => '(2/5) - (1/2)', output => ' 2     1 
--- - ---
 5     2 ', height => 3, width => 9 },
	test_011 => { expr => '((2/5) - (1/2))/(x+y)', output => '  2     1  
 --- - --- 
  5     2  
-----------
   x + y   ', height => 5, width => 11 },
	test_012 => { expr => 'sin(((2/5) - (1/2))/(x+y))', output => '   (  2     1  )
   ( --- - --- )
sin(  5     2  )
   (-----------)
   (   x + y   )', height => 5, width => 16 },
	test_013 => { expr => 'sin(((2/5) - (1/2)))/(x+y)', output => '    ( 2     1 ) 
 sin(--- - ---) 
    ( 5     2 ) 
----------------
     x + y      ', height => 5, width => 16 },
	test_014 => { expr => '5^(1/2)', output => 'sqrt(5)', height => 1, width => 7 },
	test_015 => { expr => '(5^(1/2))/sin(6^(3/8))', output => '   sqrt(5)    
--------------
    (  ( 3 )) 
    (  (---)) 
 sin(  ( 8 )) 
    (6^     ) ', height => 6, width => 14 },
	test_016 => { expr => '(x + 5) * 2', output => '(x + 5)*2', height => 1, width => 9 },
	test_017 => { expr => '(x + 5) ^ 2', output => '        2
(x + 5)^ ', height => 2, width => 9 },
	test_018 => { expr => '(x + 5) ^ (2*t)', output => '        (2*t)
(x + 5)^     ', height => 2, width => 13 },
	test_019 => { expr => '(x + 5) ^ ((2*t)/3)', output => '        ( 2*t )
        (-----)
        (  3  )
(x + 5)^       ', height => 4, width => 15 },
	test_020 => { expr => '(x + 5) * 2^x', output => '          x
(x + 5)*2^ ', height => 2, width => 11 },
	test_021 => { expr => '(x + 5 + y) * 3^2^x', output => '                x
(x + 5 + y)*  2^ 
            3^   ', height => 3, width => 17 },
	test_022 => { expr => 'K + (K * ((1 - exp(-2 * K * t))/(1 + exp(-2 * K * t))) )', output => '    (           (-2*K*t) )
    (     1 - e^         )
K + (K * ----------------)
    (           (-2*K*t) )
    (     1 + e^         )', height => 5, width => 26 },
	test_023 => { expr => 'K + (K * ((1 - exp(2 * K * t))/(1 + exp(2 * K * t))) )', output => '    (           (2*K*t) )
    (     1 - e^        )
K + (K * ---------------)
    (           (2*K*t) )
    (     1 + e^        )', height => 5, width => 25 },
	test_024 => { expr => 'ln(x)', output => 'ln(x)', height => 1, width => 5 },
	test_025 => { expr => 'ln(x/2)', output => '  ( x )
ln(---)
  ( 2 )', height => 3, width => 7 },
	test_026 => { expr => '5 ^ 0.5', output => 'sqrt(5)', height => 1, width => 7 },
	test_027 => { expr => '(x + y + z) ^ (1/2)', output => 'sqrt(x + y + z)', height => 1, width => 15 },
	test_028 => { expr => 'log(5, x)', output => 'log(5 , x)', height => 1, width => 10 },
	test_029 => { expr => 'log(5^y, ((2/5) - (1/2)))', output => '   (  y    2     1 )
log(5^  , --- - ---)
   (       5     2 )', height => 3, width => 20 },
	test_030 => { expr => '((e^x) + (e^-x))/2', output => '   x     -x 
 e^  + e^   
------------
     2      ', height => 4, width => 12 },
	test_031 => { expr => 'x^2 + 2*x + 1', output => '  2          
x^  + 2*x + 1', height => 2, width => 13 },
	test_032 => { expr => '3*x^3 - x^2 + 2*x + 1', output => '    3     2          
3*x^  - x^  + 2*x + 1', height => 2, width => 21 },
);

while ( my ($test, $tdata) = each %tests ) {

    my $expr = parse_from_string($tdata->{expr});
    ok( defined $expr, "$test: Parser returned expression" );

    my $string = $expr->to_tall_string();
    ok( defined $string, "$test: to_tall_string() returned output" );

    ok( $string eq $tdata->{output}, "$test: output from to_tall_string() matched test data" );
}


