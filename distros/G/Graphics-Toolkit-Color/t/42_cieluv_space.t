#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 143;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELUV';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'LUV', 'color space name is CIELUV');
is( $space->alias,                       'CIELUV', 'color space alias is LUV');
is( $space->is_name('cieLUV'),                  1, 'full space  name recognized');
is( $space->is_name('Luv'),                     1, 'axis initials do qual space name');
is( $space->is_name('Lab'),                     0, 'axis initials do not equal space name this time');
is( $space->axis_count,                         3, 'color space has 3 dimensions');

is( ref $space->check_value_shape([0, 0, 0]),          'ARRAY', 'check minimal CIELUV values are in bounds');
is( ref $space->check_value_shape([0.950, 1, 1.088]),  'ARRAY', 'check maximal CIELUV values');
is( ref $space->check_value_shape([0,0]),                   '', "CIELUV got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),            '', "CIELUV got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),            '', "L value is too small");
is( ref $space->check_value_shape([100, 0, 0]),        'ARRAY', 'L value is maximal');
is( ref $space->check_value_shape([101, 0, 0]),             '', "L value is too big");
is( ref $space->check_value_shape([0, -134, 0]),       'ARRAY', 'u value is minimal');
is( ref $space->check_value_shape([0, -134.1, 0]),          '', "u value is too small");
is( ref $space->check_value_shape([0, 220, 0]),        'ARRAY', 'u value is maximal');
is( ref $space->check_value_shape([0, 220.1, 0]),           '', "u value is too big");
is( ref $space->check_value_shape([0, 0, -140]),       'ARRAY', 'v value is minimal');
is( ref $space->check_value_shape([0, 0, -140.1 ] ),        '', "v value is too small");
is( ref $space->check_value_shape([0, 0, 122]),        'ARRAY', 'v value is maximal');
is( ref $space->check_value_shape([0, 0, 122.2] ),          '', "v value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({u => 1, v => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({u => 1, v => 0, l => 0}), 1, 'found hash with all axis names');
is( $space->is_partial_hash({'L*' => 1, 'u*' => 0, 'v*' => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({a => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'XYZ'), 1,                 'do only convert from and to rgb');
is( $space->can_convert( 'xyz'), 1,                 'namespace can be written lower case');
is( $space->can_convert( 'CIEluv'), 0,                 'can not convert to itself');
is( $space->can_convert( 'luv'), 0,                    'can not convert to itself (alias)');
is( $space->format([0,0.234,120], 'css_string'), 'luv(0, 0.234, 120)', 'can format css string');

my $val = $space->deformat(['CIELUV', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
is( $space->format([0,1,0], 'css_string'), 'luv(0, 1, 0)', 'can format css string');

# black
$val = $space->denormalize( [0, .378531073, .534351145] );
is( ref $val,                      'ARRAY',  'denormalized black into zeros');
is( int @$val,                           3,  'right amount of values');
is( round_decimals( $val->[0] , 5),      0,  'L* value of black good');
is( round_decimals( $val->[1] , 5),      0,  'u* value of black good');
is( round_decimals( $val->[2] , 5),      0,  'v* value of black good');

$val = $space->normalize( [0, 0, 0] );
is( ref $val,                        'ARRAY',  'normalized tuple of zeros (black)');
is( int @$val,                             3,  'right amount of values');
is( round_decimals( $val->[0] , 5),        0,  'L value good');
is( round_decimals( $val->[1] , 5),  0.37853,  'u* value good');
is( round_decimals( $val->[2] , 5),  0.53435,  'v* value good');

my $luv = $space->convert_from( 'XYZ', [ 0, 0, 0]);
is( ref $luv,                        'ARRAY',  'deconverted tuple of zeros (black) from XYZ');
is( int @$luv,                             3,  'right amount of values');
is( round_decimals( $luv->[0] , 5),        0,  'first value good');
is( round_decimals( $luv->[1] , 5),  0.37853,  'second value good');
is( round_decimals( $luv->[2] , 5),  0.53435,  'third value good');

my $xyz = $space->convert_to( 'XYZ', [ 0, .378531073, .534351145 ]);
is( ref $xyz,                    'ARRAY',  'converted black to XYZ');
is( int @$xyz,                         3,  'right amount of values');
is( round_decimals( $xyz->[0] , 5),    0,  'X value good');
is( round_decimals( $xyz->[1] , 5),    0,  'Y value good');
is( round_decimals( $xyz->[2] , 5),    0,  'Z value good');

# white
$val = $space->denormalize( [1, .378531073, .534351145] );
is( ref $val,                      'ARRAY',  'denormalized white into zeros');
is( int @$val,                           3,  'right amount of values');
is( round_decimals( $val->[0] , 5),    100,  'L* value of white good');
is( round_decimals( $val->[1] , 5),      0,  'u* value of white good');
is( round_decimals( $val->[2] , 5),      0,  'v* value of white good');

$val = $space->normalize( [100, 0, 0] );
is( ref $val,                       'ARRAY',  'normalized tuple of white');
is( int @$val,                            3,  'right amount of values');
is( round_decimals( $val->[0] , 5),       1,  'L value good');
is( round_decimals( $val->[1] , 5), 0.37853,  'u* value good');
is( round_decimals( $val->[2] , 5), 0.53435,  'v* value good');

$luv = $space->convert_from( 'XYZ', [ 1, 1, 1]);
is( ref $luv,                      'ARRAY',  'converted white from XYZ to LUV');
is( int @$luv,                           3,  'right amount of values');
is( round_decimals( $luv->[0] , 5),      1,  'first value good');
is( round_decimals( $luv->[1] , 5), 0.37853,  'second value good');
is( round_decimals( $luv->[2] , 5), 0.53435,  'third value good');

$xyz = $space->convert_to( 'XYZ', [ 1, .378531073, .534351145 ]);
is( ref $xyz,                    'ARRAY',  'converted white to CIEXYZ');
is( int @$xyz,                         3,  'right amount of values');
is( round_decimals( $xyz->[0], 5),      1,  'X value good');
is( round_decimals( $xyz->[1], 5),      1,  'Y value good');
is( round_decimals( $xyz->[2], 5),      1,  'Z value good');

# red
$val = $space->denormalize( [0.53241, .872923729, .678458015] );
is( int @$val,                            3,  'denormalize red');
is( round_decimals( $val->[0], 5),  53.241,  'L* value of white good');
is( round_decimals( $val->[1], 5), 175.015,  'u* value of white good');
is( round_decimals( $val->[2], 5),  37.756,  'v* value of white good');

$val = $space->normalize( [53.241, 175.015, 37.756] );
is( int @$val,                          3,  'normalize red');
is( round_decimals( $val->[0], 5),  0.53241,  'L value good');
is( round_decimals( $val->[1], 5),  0.87292,  'u* value good');
is( round_decimals( $val->[2], 5),  0.67846,  'v* value good');

$luv = $space->convert_from( 'XYZ', [ 0.433953728, 0.21267, 0.017753001]);
is( int @$luv,                          3,  'deconverted red from CIEXYZ');
is( round_decimals( $luv->[0], 5), 0.5324,  'first value good');
is( round_decimals( $luv->[1], 4), 0.8729,  'second value good');
is( round_decimals( $luv->[2], 5), 0.67846,  'third value good');

$xyz = $space->convert_to( 'XYZ', [ 0.53241, .872923729, .678458015 ]);
is( int @$xyz,                            3,  'converted red to CIEXYZ');
is( round_decimals( $xyz->[0], 5),  0.43395,  'X value good');
is( round_decimals( $xyz->[1], 5),  0.21267,  'Y value good');
is( round_decimals( $xyz->[2], 5),  0.01776,  'Z value good');

# blue
$val = $space->denormalize( [0.32297, .351963277, .036862595] );
is( int @$val,                            3,  'denormalize blue');
is( round_decimals( $val->[0], 5),   32.297,  'L* value of white good');
is( round_decimals( $val->[1], 5),   -9.405,  'u* value of white good');
is( round_decimals( $val->[2], 5), -130.342,  'v* value of white good');

$val = $space->normalize( [32.297, -9.405, -130.342] );
is( int @$val,                              3,  'normalize blue');
is( round_decimals( $val->[0], 5),    0.32297, 'L value good');
is( round_decimals( $val->[1], 5),    0.35196, 'u* value good');
is( round_decimals( $val->[2], 5),    0.03686, 'v* value good');

$luv = $space->convert_from( 'XYZ', [ 0.1898429198, 0.07217, 0.872771690713886]);
is( int @$luv,                            3,  'deconverted blue from CIEXYZ');
is( round_decimals( $luv->[0], 5),  0.32296,  'first value good');
is( round_decimals( $luv->[1], 5),  0.35197,  'second value good');
is( round_decimals( $luv->[2], 5),  0.03687,  'third value good');

$xyz = $space->convert_to( 'XYZ', [ 0.322958956314709, 0.351970231199232, 0.0368661363328552 ]);
is( int @$xyz,                            3,  'converted blue to CIEXYZ');
is( round_decimals( $xyz->[0], 5),  0.18984,  'X value good');
is( round_decimals( $xyz->[1], 5),  0.07217,  'Y value good');
is( round_decimals( $xyz->[2], 5),  0.87277,  'Z value good');

# gray
$val = $space->denormalize( [0.53389, .378531073, .534351145] );
is( int @$val,                          3,  'denormalize gray');
is( round_decimals( $val->[0], 5), 53.389,  'L* value of white good');
is( round_decimals( $val->[1], 5),      0,  'u* value of white good');
is( round_decimals( $val->[2], 5),      0,  'v* value of white good');

$val = $space->normalize( [53.389, 0, 0] );
is( int @$val,                           3, 'normalize gray');
is( round_decimals( $val->[0], 5), 0.53389, 'L value good');
is( round_decimals( $val->[1], 5), 0.37853, 'u* value good');
is( round_decimals( $val->[2], 5), 0.53435, 'v* value good');

$luv = $space->convert_from( 'XYZ', [ .214041474 , .21404, 0.214037086]);
is( int @$luv,                           3,  'deconverted gray from XYZ');
is( round_decimals( $luv->[0], 5), 0.53389,  'first value good');
is( round_decimals( $luv->[1], 5), 0.37853,  'second value good');
is( round_decimals( $luv->[2], 5), 0.53435,  'third value good');

$xyz = $space->convert_to( 'XYZ', [ 0.53389, .378531073, .534351145 ]);
is( int @$xyz,                           3,  'converted gray to CIEXYZ');
is( round_decimals( $xyz->[0], 5), 0.21404,  'X value good');
is( round_decimals( $xyz->[1], 5), 0.21404,  'Y value good');
is( round_decimals( $xyz->[2], 5), 0.21404,  'Z value good');

# nice blue
$val = $space->denormalize( [0.24082, .352573446, .317049618] );
is( int @$val,                           3,  'denormalize nice blue');
is( round_decimals( $val->[0], 5),  24.082,  'L* value of white good');
is( round_decimals( $val->[1], 5),  -9.189,  'u* value of white good');
is( round_decimals( $val->[2], 5), -56.933,  'v* value of white good');

$val = $space->normalize( [24.082, -9.189, -56.933] );
is( int @$val,                         3,  'normalize nice blue');
is( round_decimals( $val->[0], 5), 0.24082,  'L value good');
is( round_decimals( $val->[1], 5), 0.35257,  'u* value good');
is( round_decimals( $val->[2], 5), 0.31705,  'v* value good');

$luv = $space->convert_from( 'XYZ', [ 0.057434743, .04125, .190608268]);
is( int @$luv,                         3,  'deconverted nice blue from CIEXYZ');
is( round_decimals( $luv->[0], 5),  0.2408,  'first value good');
is( round_decimals( $luv->[1], 5),  0.35258,  'second value good');
is( round_decimals( $luv->[2], 5),  0.31705,  'third value good');

$xyz = $space->convert_to( 'XYZ', [ 0.240804547340649, 0.352579240249493, 0.317048140883067 ]);
is( int @$xyz,                         3,  'converted nice blue to CIEXYZ');
is( round_decimals( $xyz->[0], 5),   0.05743,  'X value good');
is( round_decimals( $xyz->[1], 5),   0.04125,  'Y value good');
is( round_decimals( $xyz->[2], 5),   0.19061,  'Z value good');

exit 0;



