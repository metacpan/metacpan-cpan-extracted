#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 95;
BEGIN { unshift @INC, 'lib', '../lib', 't/lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

# conversion precision could be better
my $module = 'Graphics::Toolkit::Color::Space::Instance::OKLAB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                         'OKLAB', 'color space name is OKLAB');
is( $space->alias,                             '', 'color space has no alias');
is( $space->is_name('lab'),                     0, 'can not shorten the name to "LAB"');
is( $space->is_name('OKlab'),                   1, 'can mix upper and lower case');
is( $space->is_name('xyz'),                     0, 'axis initials do not equal space name this time');
is( $space->axis_count,                         3, 'oklab space has 3 axis');

is( ref $space->check_value_shape([0, -0.5, -0.5]),'ARRAY', 'check minimal OKLAB values are in bounds');
is( ref $space->check_value_shape([1, 0.5, 0.5]),  'ARRAY', 'check maximal OKLAB values');
is( ref $space->check_value_shape([0,0]),               '', "OKLAB got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),        '', "OKLAB got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),        '', "L value is too small");
is( ref $space->check_value_shape([1.01, 0, 0]),        '', "L value is too big");
is( ref $space->check_value_shape([0, -.51, 0]),        '', "a value is too small");
is( ref $space->check_value_shape([0,  .51, 0]),        '', "a value is too big");
is( ref $space->check_value_shape([0, 0, -0.51]),       '', "b value is too small");
is( ref $space->check_value_shape([0, 0, 0.52]),        '', "b value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({'L' => 1, 'a' => 0, 'b' => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({l => 1, a => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({a => 1, b => 0}), 1,  'found hash with some other keys');
is( $space->is_partial_hash({a => 1, x => 0}), 0,  'partial hash with bad keys');
is( $space->can_convert('XYZ'),    1,                 'do convert from and to xyz');
is( $space->can_convert('xyz'),    1,              'namespace can be written upper case');
is( $space->can_convert('CIELAB'), 0,              'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'oklab(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['OKLAB', 0, -.1, 0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -.1,     'second value good');
is( $val->[2],  0.1,    'third value good');
is( $space->format([0.333, -0.1, 0], 'css_string'), 'oklab(0.333, -0.1, 0)', 'can format css string');

# black
my $lab = $space->convert_from( 'XYZ', [ 0, 0, 0]);
is( ref $lab,                'ARRAY',  'convert black from CIEXYZ to OKLAB');
is( int @$lab,                     3,  'right amount of values');
is( round_decimals( $lab->[0], 3), 0,  'L value good');
is( round_decimals( $lab->[1], 3), 0.5,  'a value good');
is( round_decimals( $lab->[2], 3), 0.5,  'b value good');

my $xyz = $space->convert_to( 'XYZ', [ 0, 0.5, 0.5]);
is( ref $xyz,                    'ARRAY',  'converted black to from OKLAB to XYZ');
is( int @$xyz,                         3,  'got 3 values');
is( round_decimals( $xyz->[0] , 3),    0,  'X value good');
is( round_decimals( $xyz->[1] , 3),    0,  'Y value good');
is( round_decimals( $xyz->[2] , 3),    0,  'Z value good');

$val = $space->denormalize( [0, .5, .5] );
is( ref $val,                    'ARRAY',  'denormalized deconverted tuple of zeros (black)');
is( int @$val,                         3,  'right amount of values');
is( round_decimals( $val->[0] , 5),    0,  'L value of black good');
is( round_decimals( $val->[1] , 5),    0,  'a value of black good');
is( round_decimals( $val->[2] , 5),    0,  'b value of black good');

$val = $space->normalize( [0, 0, 0] );
is( ref $val,                    'ARRAY',  'normalized tuple of zeros (black)');
is( int @$val,                         3,  'right amount of values');
is( round_decimals( $val->[0] , 5),    0,  'L value good');
is( round_decimals( $val->[1] , 5),   .5,  'a value good');
is( round_decimals( $val->[2] , 5),   .5,  'b value good');

# white
$lab = $space->convert_from( 'XYZ', [ 1, 1, 1,]);
is( int @$lab,                          3,  'deconverted white from CIEXYZ');
is( round_decimals( $lab->[0],   3),    1,  'L value of white good');
is( round_decimals( $lab->[1],   3),   .5,  'a value of white good');
is( round_decimals( $lab->[2],   3),   .5,  'b value of white good');

$xyz = $space->convert_to( 'XYZ', [ 1, 0.5, 0.5]);
is( int @$xyz,                         3,  'converted white to CIEXYZ');
is( round_decimals( $xyz->[0] , 3),    1,  'X value of white good');
is( round_decimals( $xyz->[1] , 3),    1,  'Y value of white good');
is( round_decimals( $xyz->[2] , 3),    1,  'Z value of white good');

$val = $space->denormalize( [1, .5, .5] );
is( ref $val,                    'ARRAY',  'denormalized white');
is( int @$val,                         3,  'right amount of values');
is( round_decimals( $val->[0] , 5),    1,  'L value of black good');
is( round_decimals( $val->[1] , 5),    0,  'a value of black good');
is( round_decimals( $val->[2] , 5),    0,  'b value of black good');

$val = $space->normalize( [1, 0, 0] );
is( ref $val,                      'ARRAY',  'normalized white');
is( int @$val,                           3,  'right amount of values');
is( round_decimals( $val->[0] , 5),      1,  'L value good');
is( round_decimals( $val->[1] , 5),     .5,  'a value good');
is( round_decimals( $val->[2] , 5),     .5,  'b value good');

# bluish
$lab = $space->convert_from( 'XYZ', [ 0.153608214883163, 0.062, 0.691568013372152]);
is( int @$lab,                            3,  'deconverted a nice blue CIEXYZ');
is( round_decimals( $lab->[0],   3),   .427,  'L value of nice blue good');
is( round_decimals( $lab->[1],   3),   .474,  'a value of nice blue good');
is( round_decimals( $lab->[2],   3),   .217,  'b value of nice blue good');

$xyz = $space->convert_to( 'XYZ', [ 0.426796987209832, 0.474256066756847, 0.217395419063849]);
is( int @$xyz,                         3,  'converted white to CIEXYZ');
is( round_decimals( $xyz->[0] , 3),    0.154,  'X value of nice blue good');
is( round_decimals( $xyz->[1] , 3),    0.062,  'Y value of nice blue good');
is( round_decimals( $xyz->[2] , 3),    0.692,  'Z value of nice blue good');


# light blue
$lab = $space->convert_from( 'XYZ', [ 0.589912305, 0.6370801241100728, 0.773381978]);
is( int @$lab,                            3,  'deconverted a light blue CIEXYZ');
is( round_decimals( $lab->[0],   5),   .85623,  'L value of light blue good');
is( round_decimals( $lab->[1],   4),   .4623,  'a value of light blue good');
is( round_decimals( $lab->[2],   4),   .4687,  'b value of light blue good');

$xyz = $space->convert_to( 'XYZ', [ 0.856232267, 0.462306544, 0.468657634]);
is( int @$xyz,                         3,  'converted light blue to CIEXYZ');
is( round_decimals( $xyz->[0] , 5),    0.58991,  'X value of light blue good');
is( round_decimals( $xyz->[1] , 5),    0.637080,  'Y value of light blue good');
is( round_decimals( $xyz->[2] , 5),    0.77338,  'Z value of light blue good');

# pink
$lab = $space->convert_from( 'XYZ', [ 0.74559151, 0.6327286137205872, 0.596805462 ]);
is( int @$lab,                           3,  'deconverted pink from CIEXYZ');
is(  round_decimals($lab->[0], 5),  .86774,  'L value of pink good');
is(  round_decimals($lab->[1], 3),  .573  ,  'a value of pink good');
is(  round_decimals($lab->[2], 3),  .509  ,  'b value of pink good');

$xyz = $space->convert_to( 'XYZ', [ 0.867737127, 0.572958135, 0.508966821]);
is( int @$xyz,                           3,  'converted nice blue to CIEXYZ');
is( round_decimals( $xyz->[0], 5), 0.74559,  'X value of pink good');
is( round_decimals( $xyz->[1], 5), 0.63273,  'Y value of pink good');
is( round_decimals( $xyz->[2], 5), 0.59680,  'Z value of pink good');

exit 0;
