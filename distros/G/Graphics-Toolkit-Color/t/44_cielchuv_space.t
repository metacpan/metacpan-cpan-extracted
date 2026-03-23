#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 135;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELCHuv';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                      'CIELCHUV', 'color space name is CIELCHuv');
is( $space->alias,                        'LCHUV', 'color space has alias name: LCHuv');
is( $space->is_name('CIELCHuv'),                1, 'color space name CIELCHuv is correct');
is( $space->is_name('LCHuv'),                   1, 'color space name LCHuv is correct');
is( $space->is_name('LCH'),                     0, 'LCH is given for another space');
is( $space->axis_count,                         3, 'LCHUV has 3 dimensions');
is( $space->is_euclidean,                       0, 'LCHUV is not euclidean');
is( $space->is_cylindrical,                     1, 'LCHUV is cylindrical');

is( ref $space->check_value_shape( [0,0]),              '',   "CIELCHuv got too few values");
is( ref $space->check_value_shape( [0, 0, 0, 0]),       '',   "CIELCHuv got too many values");
is( ref $space->check_value_shape( [0, 0, 0]),          'ARRAY',   'check minimal CIELCHuv values are in bounds');
is( ref $space->check_value_shape( [100, 261, 360]),    'ARRAY',   'check maximal CIELCHuv values are in bounds');
is( ref $space->check_value_shape( [-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_value_shape( [100.01, 0, 0]),     '',   'L value is too big');
is( ref $space->check_value_shape( [0, -0.1, 0]),       '',   "c value is too small");
is( ref $space->check_value_shape( [0, 261.1, 0]),      '',   'c value is too big');
is( ref $space->check_value_shape( [0, 0, -0.1]),       '',   'h value is too small');
is( ref $space->check_value_shape( [0, 0, 360.2] ),     '',   "h value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({c => 1, h => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({l => 1, c => 0, h => 0}), 1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert('LUV'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('Luv'), 1,                 'namespace can be written lower case');
is( $space->can_convert('CIELCHuv'), 0,               'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'cielchuv(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['CIELCHuv', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
is( $space->format([0,1,0], 'css_string'), 'cielchuv(0, 1, 0)', 'can format css string');


# black
$val = $space->denormalize( [0, 0, 0] );
is( ref $val,                    'ARRAY',  'denormalized black into zeros');
is( int @$val,                         3,  'right amount of values');
is( round_decimals( $val->[0], 5),     0,  'L value is good');
is( round_decimals( $val->[1], 5),     0,  'C value is good');
is( round_decimals( $val->[2], 5),     0,  'H value is good');

$val = $space->normalize( [0, 0, 0] );
is( ref $val,                    'ARRAY',  'normalized tuple of zeros (black)');
is( int @$val,                         3,  'right amount of values');
is( round_decimals( $val->[0], 5),     0,  'L value is good');
is( round_decimals( $val->[1], 5),     0,  'C value is good');
is( round_decimals( $val->[2], 5),     0,  'H value is good');

my $lch = $space->convert_from( 'LUV', [ 0, .378531073, .534351145]);
is( ref $lch,                    'ARRAY',  'deconverted black from LUV');
is( int @$lch,                         3,  'right amount of values');
is( round_decimals( $lch->[0], 5),     0,  'L value is good');
is( round_decimals( $lch->[1], 5),     0,  'C value is good');
is( round_decimals( $lch->[2], 5),     0,  'H value is good');

my $luv = $space->convert_to( 'LUV', [ 0, 0, 0 ] );
is( ref $luv,                     'ARRAY',  'converted black to LUV');
is( int @$luv,                          3,  'right amount of values');
is( round_decimals( $luv->[0], 5),      0,  'L* value is good');
is( round_decimals( $luv->[1], 5), .37853,  'u* value is good');
is( round_decimals( $luv->[2], 5), .53435,  'v* value is good');

# white
$val = $space->denormalize( [1, 0, 0] );
is( int @$val,                         3,  'denormalized white');
is( round_decimals( $val->[0], 5),   100,  'L value of white is good');
is( round_decimals( $val->[1], 5),     0,  'C value of white is good');
is( round_decimals( $val->[2], 5),     0,  'H value of white is good');

$val = $space->normalize( [100, 0, 0] );
is( int @$val,                         3,  'normalized white');
is( round_decimals( $val->[0], 5),     1,  'L value is good');
is( round_decimals( $val->[1], 5),     0,  'C value is good');
is( round_decimals( $val->[2], 5),     0,  'H value is good');

$lch = $space->convert_from( 'LUV', [ 1, .378531073, .534351145]);
is( int @$lch,                         3,  'deconverted white from LUV');
is( round_decimals( $lch->[0], 5),     1,  'L value is good');
is( round_decimals( $lch->[1], 5),     0,  'C value is good');
is( round_decimals( $lch->[2], 5),     0,  'H value is good');

$luv = $space->convert_to( 'LUV', [ 1, 0, 0 ] );
is( int @$luv,                             3,  'converted white to LUV');
is( round_decimals( $luv->[0], 5),          1,  'L value is good');
is( round_decimals( $luv->[1], 5), .37853,  'u value is good');
is( round_decimals( $luv->[2], 5), .53435,  'v value is good');

# gray
$val = $space->denormalize( [.53389, 0, .686386111] );
is( int @$val,                           3,  'denormalized gray');
is( round_decimals( $val->[0], 5),  53.389,  'L value is good');
is( round_decimals( $val->[1], 5),       0,  'C value is good');
is( round_decimals( $val->[2], 5), 247.099,  'H value is good');

$val = $space->normalize( [53.389, 0, 247.099] );
is( int @$val,                            3,  'normalized gray');
is( round_decimals( $val->[0], 5),   .53389,  'L value good');
is( round_decimals( $val->[1], 5),        0,  'C value good');
is( round_decimals( $val->[2], 5),  0.68639,  'H value good');

$lch = $space->convert_from( 'LUV', [ .53389, .378531073, .534351145] );
is( int @$lch,                          3,  'deconverted gray from LUV');
is( round_decimals( $lch->[0], 5), .53389,  'L value is good');
is( round_decimals( $lch->[1], 5),      0,  'C value is good');
is( round_decimals( $lch->[2], 5),      0,  'H value is good');

$luv = $space->convert_to( 'LUV', [ .53389, 0, 0.686386111 ] );
is( int @$luv,                           3,  'converted gray to LUV');
is( round_decimals( $luv->[0], 5),  .53389,  'L value is good');
is( round_decimals( $luv->[1], 5),  .37853,  'u value is good');
is( round_decimals( $luv->[2], 5),  .53435,  'v value is good');

# red
$val = $space->denormalize( [.53389, 0.685980843, .033816667] );
is( int @$val,                           3,  'denormalized red');
is( round_decimals( $val->[0], 5),  53.389,  'L value is good');
is( round_decimals( $val->[1], 5), 179.041,  'C value is good');
is( round_decimals( $val->[2], 5),  12.174,  'H value is good');

$val = $space->normalize( [53.389, 179.041, 12.174] );
is( int @$val,                         3,  'normalized red');
is( round_decimals( $val->[0], 5),  .53389,  'L value good');
is( round_decimals( $val->[1], 5),  .68598,  'C value good');
is( round_decimals( $val->[2], 5),  .03382,  'H value good');

$lch = $space->convert_from( 'LUV', [ .53389, .872923729, .678458015] );
is( int @$lch,                           3,  'deconverted red from LUV');
is( round_decimals( $lch->[0], 5),  .53389,  'L value good');
is( round_decimals( $lch->[1], 5),  .68598,  'C value good');
is( round_decimals( $lch->[2], 5),  .03382,  'H value good');

$luv = $space->convert_to( 'LUV', [ .53389, 0.685980843, .033816667 ] );
is( int @$luv,                         3,  'converted red to LUV');
is( round_decimals( $luv->[0], 5),  .53389,  'L value good');
is( round_decimals( $luv->[1], 5),  .87292,  'u value good');
is( round_decimals( $luv->[2], 5),  .67846,  'v value good');

# blue
$val = $space->denormalize( [.32297, 0.500693487, .738536111] );
is( int @$val,                           3,  'denormalized blue');
is( round_decimals( $val->[0], 5),  32.297,  'L value is good');
is( round_decimals( $val->[1], 5), 130.681,  'C value is good');
is( round_decimals( $val->[2], 5), 265.873,  'H value is good');

$val = $space->normalize( [32.297, 130.681, 265.873] );
is( int @$val,                          3,  'normalized blue');
is( round_decimals( $val->[0], 5), .32297,  'L value good');
is( round_decimals( $val->[1], 5), .50069,  'C value good');
is( round_decimals( $val->[2], 5), .73854,  'H value good');

$lch = $space->convert_from( 'LUV', [ .32297, .351963277, .036862595]);
is( int @$lch,                         3,  'deconverted blue from LUV');
is( round_decimals( $lch->[0], 5), .32297,  'L value good');
is( round_decimals( $lch->[1], 5), .50069,  'C value good');
is( round_decimals( $lch->[2], 5), .73854,  'H value good');

$luv = $space->convert_to( 'LUV', [ .32297, 0.500693487, .738536111 ]);
is( int @$luv,                         3,  'converted blue to LUV');
is( round_decimals( $luv->[0], 5),  .32297,  'L value good');
is( round_decimals( $luv->[1], 5),  .35196,  'u value good');
is( round_decimals( $luv->[2], 5),  .03686,  'v value good');

# mid blue
$val = $space->denormalize( [.24082, 0.220954023, .724533333] );
is( int @$val,                           3,  'denormalized mid blue');
is( round_decimals( $val->[0], 5),  24.082,  'L value is good');
is( round_decimals( $val->[1], 5),  57.669,  'C value is good');
is( round_decimals( $val->[2], 5), 260.832,  'H value is good');

$val = $space->normalize( [24.082, 57.669, 260.832] );
is( int @$val,                         3,  'normalized mid blue');
is( round_decimals( $val->[0], 5),  .24082,  'L value good');
is( round_decimals( $val->[1], 5),  .22095,  'C value good');
is( round_decimals( $val->[2], 5),  .72453,  'H value good');

$lch = $space->convert_from( 'LUV', [ .24082, .352573446, .317049618] );
is( int @$lch,                         3,  'deconverted mid blue from LUV');
is( round_decimals( $lch->[0], 5), .24082,  'L value good');
is( round_decimals( $lch->[1], 5), .22096,  'C value good');
is( round_decimals( $lch->[2], 5), .72453,  'H value good');

$luv = $space->convert_to( 'LUV', [ 0.24082, 0.220957034629279, 0.724531985277748 ] );
is( int @$luv,                         3,  'converted mid blue to LUV');
is( round_decimals( $luv->[0], 5),  .24082,  'L value good');
is( round_decimals( $luv->[1], 5),  .35257,  'u value good');
is( round_decimals( $luv->[2], 5),  .31705,  'v value good');

exit 0;
