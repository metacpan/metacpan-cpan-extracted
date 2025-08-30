#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 104;
BEGIN { unshift @INC, 'lib', '../lib', 't/lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';


my $module = 'Graphics::Toolkit::Color::Space::Instance::HunterLAB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                     'HUNTERLAB', 'color space official name is "HUNTERLAB"');
is( $space->alias,                             '', 'no color space alias name');
is( $space->is_name('HunterLAB'),               1, 'color space name HunterLAB is correct');
is( $space->is_name('CIElab'),                  0, 'not to be confused with "CIELAB"');
is( $space->is_name('lab'),                     0, 'axis initials do not equal space name this time');
is( $space->axis_count,                         3, 'color space has 3 axis');

# K: 172,355206019 67,038696071
is( ref $space->check_value_shape([0, -172.30, -67.03]),'ARRAY',  'check minimal HunterLAB values are in bounds');
is( ref $space->check_value_shape([100, 172.30, 67.03]),'ARRAY',  'check maximal HunterLAB values');
is( ref $space->check_value_shape([0,0]),              '',   "HunterLAB got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "HunterLAB got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_value_shape([101, 0, 0]),        '',   "L value is too big");
is( ref $space->check_value_shape([1, -172.4, 0]),     '',   "a value is too small");
is( ref $space->check_value_shape([1, 172.4, 0]),      '',   "a value is too big");
is( ref $space->check_value_shape([0, 0, -67.21 ] ),   '',   "b value is too small");
is( ref $space->check_value_shape([0, 0, 67.21] ),     '',   "b value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({'L' => 1, 'a' => 0, 'b' => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({'L' => 1, 'a' => 0, 'b*' => 0}), 0, 'not confused with lab Hash');
is( $space->is_partial_hash({l => 1, a => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({a => 1, b => 0}), 1,  'found hash with some other keys');
is( $space->is_partial_hash({a => 1, x => 0}), 0,  'partial hash with bad keys');
is( $space->can_convert('XYZ'),    1,              'do convert from and to xyz');
is( $space->can_convert('xyz'),    1,              'namespace can be written lower case');
is( $space->can_convert('HunterLAB'), 0,           'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'hunterlab(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['HunterLAB', 100, 0, -67.1]);
is( ref $val,           'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,                3, 'right amount of values');
is( $val->[0],              100, 'first value good');
is( $val->[1],                0, 'second value good, zeros no issue');
is( $val->[2],            -67.1, 'third value good');
is( $space->format([11.1, 5, 0], 'named_string'), 'hunterlab: 11.1, 5, 0', 'can format named string');

# black
my $lab = $space->convert_from( 'XYZ', [ 0, 0, 0]);
is( ref $lab,                     'ARRAY',  'convert black from CIEXYZ to HunterLAB');
is( int @$lab,                          3,  'right amount of values');
is( round_decimals( $lab->[0], 5),      0,  'L value good');
is( round_decimals( $lab->[1], 5),    0.5,  'a value good');
is( round_decimals( $lab->[2], 5),    0.5,  'b value good');

my $xyz = $space->convert_to( 'XYZ', [ 0, 0.5, 0.5]);
is( ref $xyz,                     'ARRAY',  'converted black to from HunterLAB to XYZ');
is( int @$xyz,                          3,  'got 3 values');
is( round_decimals( $xyz->[0] , 5),     0,  'X value good');
is( round_decimals( $xyz->[1] , 5),     0,  'Y value good');
is( round_decimals( $xyz->[2] , 5),     0,  'Z value good');

$val = $space->denormalize( [0, .5, .5] );
is( ref $val,                     'ARRAY',  'denormalized deconverted tuple of zeros (black)');
is( int @$val,                          3,  'right amount of values');
is( round_decimals( $val->[0] , 5),     0,  'L value of black good');
is( round_decimals( $val->[1] , 5),     0,  'a value of black good');
is( round_decimals( $val->[2] , 5),     0,  'b value of black good');

$val = $space->normalize( [0, 0, 0] );
is( ref $val,                     'ARRAY',  'normalized tuple of zeros (black)');
is( int @$val,                          3,  'right amount of values');
is( round_decimals( $val->[0] , 5),     0,  'L value good');
is( round_decimals( $val->[1] , 5),    .5,  'a value good');
is( round_decimals( $val->[2] , 5),    .5,  'b value good');

# white
$lab = $space->convert_from( 'XYZ', [ 1, 1, 1,]);
is( int @$lab,                          3,  'deconverted white from CIEXYZ');
is( round_decimals( $lab->[0],   5),    1,  'L value of white good');
is( round_decimals( $lab->[1],   5),   .5,  'a value of white good');
is( round_decimals( $lab->[2],   5),   .5,  'b value of white good');

$xyz = $space->convert_to( 'XYZ', [ 1, 0.5, 0.5]);
is( int @$xyz,                          3,  'converted white to CIEXYZ');
is( round_decimals( $xyz->[0] , 1),     1,  'X value of white good');
is( round_decimals( $xyz->[1] , 1),     1,  'Y value of white good');
is( round_decimals( $xyz->[2] , 1),     1,  'Z value of white good');

$val = $space->denormalize( [1, .5, .5] );
is( ref $val,                     'ARRAY',  'denormalized white');
is( int @$val,                          3,  'right amount of values');
is( round_decimals( $val->[0] , 5),   100,  'L value of black good');
is( round_decimals( $val->[1] , 5),     0,  'a value of black good');
is( round_decimals( $val->[2] , 5),     0,  'b value of black good');

$val = $space->normalize( [100, 0, 0] );
is( ref $val,                     'ARRAY',  'normalized white');
is( int @$val,                          3,  'right amount of values');
is( round_decimals( $val->[0] , 5),     1,  'L value good');
is( round_decimals( $val->[1] , 5),    .5,  'a value good');
is( round_decimals( $val->[2] , 5),    .5,  'b value good');

# nice blue
$lab = $space->convert_from( 'XYZ', [ 0.08729316023, 0.053706547, 0.28223099106]);
is( int @$lab,                           3,  'deconverted nice blue from CIEXYZ');
is(  round_decimals($lab->[0], 5),  .23175,  'L value of nice blue good');
is(  round_decimals($lab->[1], 5),  .57246,  'a value of nice blue good');
is(  round_decimals($lab->[2], 5),  .00695  ,  'b value of nice blue good');

$xyz = $space->convert_to( 'XYZ', [ 0.231746730289771, 0.57246405, 0.006952172]);
is( int @$xyz,                           3, 'converted nice blue to CIEXYZ');
is( round_decimals( $xyz->[0], 5), 0.08729, 'X value of nice blue good');
is( round_decimals( $xyz->[1], 5), 0.05371, 'Y value of nice blue good');
is( round_decimals( $xyz->[2], 5), 0.28223, 'Z value of nice blue good');

$val = $space->denormalize( [0.231746730289771, 0.57246405, 0.006952172] );
is( int @$val,                               3, 'denormalized nice blue');
is( round_decimals( $val->[0], 5),    23.17467, 'L value of nice blue good');
is( round_decimals( $val->[1], 3),    24.979  , 'a value of nice blue good');
is( round_decimals( $val->[2], 3),   -66.107  , 'b value of nice blue good');

$val = $space->normalize( [23.17467, 24.979, -66.107] );
is( int @$val,                               3, 'normalized nice blue');
is( round_decimals( $val->[0], 5),     0.23175, 'L value good');
is( round_decimals( $val->[1], 5),     0.57246, 'a value good');
is( round_decimals( $val->[2], 5),     0.00695, 'b value good');

# pink
$lab = $space->convert_from( 'XYZ', [0.487032731, 0.25180, 0.208186769 ]);
is( int @$lab,                           3,  'deconverted pink from CIEXYZ');
is(  round_decimals($lab->[0], 5),  .50180,  'L value of pink good');
is(  round_decimals($lab->[1], 5),  .73439,  'a value of pink good');
is(  round_decimals($lab->[2], 5),  .54346,  'b value of pink good');

$xyz = $space->convert_to( 'XYZ', [ 0.501796772, 0.734390439, 0.543457066]);
is( int @$xyz,                           3,  'converted nice blue to CIEXYZ');
is( round_decimals( $xyz->[0], 5), 0.48703,  'X value of pink good');
is( round_decimals( $xyz->[1], 5), 0.25180,  'Y value of pink good');
is( round_decimals( $xyz->[2], 5), 0.20819,  'Z value of pink good');

$val = $space->denormalize( [0.501796772, 0.734390439, 0.543457066] );
is( int @$val,                          3,  'denormalized pink');
is( round_decimals( $val->[0], 3), 50.180,  'L value of pink good');
is( round_decimals( $val->[1], 3), 80.797,  'a value of pink good');
is( round_decimals( $val->[2], 3),  5.827,  'b value of pink good');

$val = $space->normalize( [50.180, 80.797, 5.827] );
is( int @$val,                         3,  'normalized pink');
is( round_decimals( $val->[0], 5), 0.50180,  'L value of pink good');
is( round_decimals( $val->[1], 5), 0.73439,  'a value of pink good');
is( round_decimals( $val->[2], 5), 0.54346,  'b value of pink good');

exit 0;
