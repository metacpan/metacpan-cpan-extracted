#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 103;
BEGIN { unshift @INC, 'lib', '../lib', 't/lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';


my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELAB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'LAB', 'color space name is LAB');
is( $space->alias,                       'CIELAB', 'color space alias name is CIELAB');
is( $space->is_name('lab'),                     1, 'color space name NCol is correct');
is( $space->is_name('CIElab'),                  1, 'axis initials do not equal space name this time');
is( $space->is_name('xyz'),                     0, 'axis initials do not equal space name this time');
is( $space->axis_count,        3,                  'color space has 3 axis');

is( ref $space->check_value_shape([0, 0, 0]),          'ARRAY',   'check minimal CIELAB values are in bounds');
is( ref $space->check_value_shape([0.950, 1, 1.088]),  'ARRAY',   'check maximal CIELAB values');
is( ref $space->check_value_shape([0,0]),              '',   "CIELAB got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "CIELAB got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_value_shape([101, 0, 0]),        '',   "L value is too big");
is( ref $space->check_value_shape([0, -500.1, 0]),     '',   "a value is too small");
is( ref $space->check_value_shape([0, 500.1, 0]),      '',   "a value is too big");
is( ref $space->check_value_shape([0, 0, -200.1 ] ),   '',   "b value is too small");
is( ref $space->check_value_shape([0, 0, 200.2] ),     '',   "b value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({'L*' => 1, 'a*' => 0, 'b*' => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({l => 1, a => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({a => 1, b => 0}), 1,  'found hash with some other keys');
is( $space->is_partial_hash({a => 1, x => 0}), 0,  'partial hash with bad keys');
is( $space->can_convert('XYZ'),    1,                 'do convert from and to xyz');
is( $space->can_convert('xyz'),    1,              'namespace can be written upper case');
is( $space->can_convert('CIELAB'), 0,              'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'lab(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['CIELAB', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
is( $space->format([0,1,0], 'css_string'), 'lab(0, 1, 0)', 'can format css string');

# black
my $lab = $space->convert_from( 'XYZ', [ 0, 0, 0]);
is( ref $lab,                    'ARRAY',  'convert black from CIEXYZ to CIELAB');
is( int @$lab,                         3,  'right amount of values');
is( round_decimals( $lab->[0], 5), 0  ,    'L* value good');
is( round_decimals( $lab->[1], 5), 0.5,    'a* value good');
is( round_decimals( $lab->[2], 5), 0.5,    'b* value good');

my $xyz = $space->convert_to( 'XYZ', [ 0, 0.5, 0.5]);
is( ref $xyz,                    'ARRAY',  'converted black to from LAB to XYZ');
is( int @$xyz,                         3,  'got 3 values');
is( round_decimals( $xyz->[0] , 5),    0,  'X value good');
is( round_decimals( $xyz->[1] , 5),    0,  'Y value good');
is( round_decimals( $xyz->[2] , 5),    0,  'Z value good');

$val = $space->denormalize( [0, .5, .5] );
is( ref $val,                    'ARRAY',  'denormalized deconverted tuple of zeros (black)');
is( int @$val,                         3,  'right amount of values');
is( round_decimals( $val->[0] , 5),    0,  'L* value of black good');
is( round_decimals( $val->[1] , 5),    0,  'a* value of black good');
is( round_decimals( $val->[2] , 5),    0,  'b* value of black good');

$val = $space->normalize( [0, 0, 0] );
is( ref $val,                    'ARRAY',  'normalized tuple of zeros (black)');
is( int @$val,                         3,  'right amount of values');
is( round_decimals( $val->[0] , 5),    0,  'L value good');
is( round_decimals( $val->[1] , 5),   .5,  'a* value good');
is( round_decimals( $val->[2] , 5),   .5,  'b* value good');

# white
$lab = $space->convert_from( 'XYZ', [ 1, 1, 1,]);
is( int @$lab,                          3,  'deconverted white from CIEXYZ');
is( round_decimals( $lab->[0],   5),    1,  'L* value of white good');
is( round_decimals( $lab->[1],   5),    .5,  'a* value of white good');
is( round_decimals( $lab->[2],   5),    .5,  'b* value of white good');

$xyz = $space->convert_to( 'XYZ', [ 1, 0.5, 0.5]);
is( int @$xyz,                         3,  'converted white to CIEXYZ');
is( round_decimals( $xyz->[0] , 1),      1,  'X value of white good');
is( round_decimals( $xyz->[1] , 1),      1,  'Y value of white good');
is( round_decimals( $xyz->[2] , 1),      1,  'Z value of white good');

$val = $space->denormalize( [1, .5, .5] );
is( ref $val,                    'ARRAY',  'denormalized white');
is( int @$val,                         3,  'right amount of values');
is( round_decimals( $val->[0] , 5),  100,  'L* value of black good');
is( round_decimals( $val->[1] , 5),    0,  'a* value of black good');
is( round_decimals( $val->[2] , 5),    0,  'b* value of black good');

$val = $space->normalize( [100, 0, 0] );
is( ref $val,                      'ARRAY',  'normalized white');
is( int @$val,                           3,  'right amount of values');
is( round_decimals( $val->[0] , 5),      1,  'L value good');
is( round_decimals( $val->[1] , 5),     .5,  'a* value good');
is( round_decimals( $val->[2] , 5),     .5,  'b* value good');

# nice blue
$lab = $space->convert_from( 'XYZ', [ 0.0872931606914908, 0.0537065470652866, 0.282231548430505]);
is( int @$lab,                            3,  'deconverted nice blue from CIEXYZ');
is(  round_decimals($lab->[0], 5),  0.27766,  'L* value of nice blue good');
is(  round_decimals($lab->[1], 5),  0.53316,  'a* value of nice blue good');
is(  round_decimals($lab->[2], 5),  0.36067,  'b* value of nice blue good');

$xyz = $space->convert_to( 'XYZ', [ .277656852, 0.5331557592, 0.3606718]);
is( int @$xyz,                           3, 'converted nice blue to CIEXYZ');
is( round_decimals( $xyz->[0], 5), 0.08729, 'X value of nice blue good');
is( round_decimals( $xyz->[1], 5), 0.05371, 'Y value of nice blue good');
is( round_decimals( $xyz->[2], 5), 0.28223, 'Z value of nice blue good');

$val = $space->denormalize( [0.277656852, 0.5331557592, 0.3606718] );
is( int @$val,                            3, 'denormalized nice blue');
is( round_decimals( $val->[0], 5), 27.76569, 'L* value of nice blue good');
is( round_decimals( $val->[1], 5), 33.15576, 'a* value of nice blue good');
is( round_decimals( $val->[2], 5),-55.73128, 'b* value of nice blue good');

$val = $space->normalize( [27.7656852, 33.156, -55.731] );
is( int @$val,                         3,  'normalized nice blue');
is( round_decimals( $val->[0], 5), 0.27766,     'L value good');
is( round_decimals( $val->[1], 5), 0.53316,     'a* value good');
is( round_decimals( $val->[2], 5), 0.36067,     'b* value good');

# pink
$lab = $space->convert_from( 'XYZ', [0.487032731, 0.25180, 0.208186769 ]);
is( int @$lab,                            3,  'deconverted pink from CIEXYZ');
is(  round_decimals($lab->[0], 5),  0.57250,  'L* value of pink good');
is(  round_decimals($lab->[1], 5),  0.57766,  'a* value of pink good');
is(  round_decimals($lab->[2], 5),  0.5194,   'b* value of pink good');

$xyz = $space->convert_to( 'XYZ', [ 0.572503826652422, 0.57765505274346, 0.519396157464772]);
is( int @$xyz,                           3,  'converted nice blue to CIEXYZ');
is( round_decimals( $xyz->[0], 5), 0.48703,  'X value of pink good');
is( round_decimals( $xyz->[1], 5), 0.25180,  'Y value of pink good');
is( round_decimals( $xyz->[2], 5), 0.20819,  'Z value of pink good');

$val = $space->denormalize( [0.57250, 0.577658, 0.5193925] );
is( int @$val,                          3,  'denormalized pink');
is( round_decimals( $val->[0], 5), 57.250,  'L* value of pink good');
is( round_decimals( $val->[1], 5), 77.658,  'a* value of pink good');
is( round_decimals( $val->[2], 5),  7.757,  'b* value of pink good');

$val = $space->normalize( [57.25, 77.658, 7.757] );
is( int @$val,                         3,  'normalized pink');
is( round_decimals( $val->[0], 5), 0.57250,  'L value of pink good');
is( round_decimals( $val->[1], 5), 0.57766,  'a* value of pink good');
is( round_decimals( $val->[2], 5), 0.51939,  'b* value of pink good');

exit 0;
