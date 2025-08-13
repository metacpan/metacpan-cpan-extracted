#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 40;

BEGIN { unshift @INC, 'lib', '../lib' }
my $module = 'Graphics::Toolkit::Color::Space::Util';

eval "use $module";
is( not($@), 1, 'could load the module');

my $round = \&Graphics::Toolkit::Color::Space::Util::round_int;
is( $round->(0.5),           1,     'round 0.5 upward');
is( $round->(0.500000001),   1,     'everything above 0.5 gets also increased');
is( $round->(0.4999999),     0,     'everything below 0.5 gets smaller');
is( $round->(-0.5),         -1,     'round -0.5 downward');
is( $round->(-0.500000001), -1,     'everything below -0.5 gets also lowered');
is( $round->(-0.4999999),    0,     'everything upward from -0.5 gets increased');
is( $round->( 1.4999999),    1,     'positive rounding works above 1');
is( $round->(-1.4999999),   -1,     'negative rounding works below 1');

my $rd = \&Graphics::Toolkit::Color::Space::Util::round_decimals;
is( $rd->( 1.4999999),    1,     'positive rounding works above 1 with round 2');
is( $rd->(-1.4999999),   -1,     'negative rounding works below 1 with round 2');
is( $rd->( 1.4999999, 0),    1,  'positive rounding with no decimals');
is( $rd->(-1.4999999, 0),   -1,  'negative rounding with no decimals');
is( $rd->( 1.4999999, 1),  1.5,  'positive rounding with one decimal');
is( $rd->(-1.4999999, 1), -1.5,  'negative rounding with one decimal');
is( $rd->( 1.4999999, 2),  1.5,  'positive rounding with one decimal');
is( $rd->(-1.4999999, 2), -1.5,  'negative rounding with one decimal');


my $rmod = \&Graphics::Toolkit::Color::Space::Util::real_mod;
is( $rmod->(),                       0,     'default to 0 when both values missing');
is( $rmod->(1),                      0,     'default to 0 when a value is missing');
is( $rmod->(1,0),                    0,     'default to 0 when a divisor is zero');
is( $rmod->(3, 2),                   1,     'normal int mod');
is( $rmod->(-3, 2),                 -1,     'int mod with negative dividend');
is( $rmod->(3, -2),                  1,     'int mod with negative divisor');
is( $rmod->(-3, -2),                -1,     'int mod with negative divisor');

my $min = \&Graphics::Toolkit::Color::Space::Util::min;
my $max = \&Graphics::Toolkit::Color::Space::Util::max;

is( $min->(1,2,3),       1  ,        'simple minimum');
is( $min->(-1.1,2,3),   -1.1,        'negative minimum');
is( $max->(1,2,3),         3,        'simple maximum');
is( $max->(-1,2,10E3), 10000,        'any syntax maximum');

my $MM = \&Graphics::Toolkit::Color::Space::Util::mult_matrix3;
my @rv = $MM->([[1,2,3],[1,2,3],[1,2,3],], 0,0,0);
is( int @rv,   3,        'result of matrix multiplication has length of 3');
is( $rv[0],    0,        'first value of matrix multiplication result is 0');
is( $rv[1],    0,        'second value of matrix multiplication result is 0');
is( $rv[2],    0,        'third value of matrix multiplication result is 0');

@rv = $MM->([[1,0,0],[0,1,0],[0,0,1],], 1.1,2.2,3.3);
is( int @rv,   3,        'result of identitiy multiplication has length of 3');
is( $rv[0],    1.1,      'first value of identitiy multiplication result is 1.1');
is( $rv[1],    2.2,      'second value of identitiy multiplication result is 2.2');
is( $rv[2],    3.3,      'third value of identitiy multiplication result is 3.3');

@rv = $MM->([[1,2,3],[4,5,6],[7,8,9],], 0, 2, 1.1);
is( int @rv,   3,        'result of full multiplication has length of 3');
is( $rv[0],    7.3,      'first value of full multiplication result is 7.3');
is( $rv[1],   16.6,      'second value of full multiplication result is 16.6');
is( $rv[2],   25.9,      'third value of full multiplication result is 25.9');

exit 0;
