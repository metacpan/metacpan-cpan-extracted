#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 134;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELCHab';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'LCH', 'color space name is LCH');
is( $space->alias,                     'CIELCHAB', 'color space name alias name is CIELCHab');
is( $space->is_name('CIELCHab'),                1, 'color space name CIELCHab is correct');
is( $space->is_name('LCH'),                     1, 'color space name LCH is correct');
is( $space->is_name('hab'),                     0, 'color space name LCH is correct');
is( $space->axis_count,                         3, 'color space has 3 dimensions');

is( ref $space->check_value_shape([0,0]),             '',   "CIELCHab got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),      '',   "CIELCHab got too many values");
is( ref $space->check_value_shape([0, 0, 0]),         'ARRAY',   'check minimal CIELCHab values are in bounds');
is( ref $space->check_value_shape([100, 539, 360]),   'ARRAY',   'check maximal CIELCHab values are in bounds');
is( ref $space->check_value_shape([-0.1, 0, 0]),      '',   "L value is too small");
is( ref $space->check_value_shape([100.01, 0, 0]),    '',   'L value is too big');
is( ref $space->check_value_shape([0, -0.1, 0]),      '',   "c value is too small");
is( ref $space->check_value_shape([0, 539.1, 0]),     '',   'c value is too big');
is( ref $space->check_value_shape([0, 0, -0.1]),      '',   'h value is too small');
is( ref $space->check_value_shape([0, 0, 360.2] ),    '',   "h value is too big");

is( $space->is_value_tuple([0,0,0]),                   1,  'tuple has 3 elements');
is( $space->is_partial_hash({c => 1, h => 0}),         1,  'found hash with some axis names');
is( $space->is_partial_hash({l => 1, c => 0, h => 0}), 1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'LAB'),                       1, 'do only convert from and to CIELAB');
is( $space->can_convert( 'Lab'),                       1, 'namespace can be written lower case');
is( $space->can_convert( 'CIELCHab'),                  0, 'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'lch(0, 0, 0)','can format css string');

my $val = $space->deformat(['CIELCHab', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
$val = $space->deformat(['LCH', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'space name (short) was recognized in named ARRAY format');
is( $space->format([0,11,350], 'css_string'), 'lch(0, 11, 350)', 'can format css string');


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

my $lch = $space->convert_from( 'LAB',  [ 0, 0.5, 0.5]);
is( ref $lch,                   'ARRAY',  'deconverted black from LAB');
is( int @$lch,                        3,  'right amount of values');
is( round_decimals( $lch->[0], 5),    0,  'L value is good');
is( round_decimals( $lch->[1], 5),    0,  'C value is good');
is( round_decimals( $lch->[2], 5),    0,  'H value is good');

my $lab = $space->convert_to( 'LAB',  [ 0, 0, 0 ]);
is( ref $lab,                    'ARRAY',  'converted black to LAB');
is( int @$lab,                         3,  'right amount of values');
is( round_decimals( $lab->[0], 5),     0,  'L* value is good');
is( round_decimals( $lab->[1], 5),    .5,  'a* value is good');
is( round_decimals( $lab->[2], 5),    .5,  'b* value is good');

# white
$val = $space->denormalize( [1, 0, 0] );
is( int @$val,                          3,  'denormalized white');
is( round_decimals( $val->[0], 5),    100,  'L value of white is good');
is( round_decimals( $val->[1], 5),      0,  'C value of white is good');
is( round_decimals( $val->[2], 5),      0,  'H value of white is good');

$val = $space->normalize( [100, 0, 0] );
is( int @$val,                        3,  'normalized white');
is( round_decimals( $val->[0], 5),    1,  'L value is good');
is( round_decimals( $val->[1], 5),    0,  'C value is good');
is( round_decimals( $val->[2], 5),    0,  'H value is good');

$lch = $space->convert_from( 'LAB',  [ 1, .5, .5]);
is( int @$lch,                        3,  'deconverted white from LAB');
is( round_decimals( $lch->[0], 5),    1,  'L value is good');
is( round_decimals( $lch->[1], 5),    0,  'C value is good');
is( round_decimals( $lch->[2], 5),    0,  'H value is good');

$lab = $space->convert_to( 'LAB',  [ 1, 0, 0 ]);
is( int @$lab,                      3,  'converted white to LAB');
is( round_decimals( $lab->[0], 5),  1,  'L value is good');
is( round_decimals( $lab->[1], 5), .5,  'u value is good');
is( round_decimals( $lab->[2], 5), .5,  'v value is good');

# gray
$val = $space->denormalize( [.53389, 0, .686386111] );
is( int @$val,                           3,  'denormalized gray');
is( round_decimals( $val->[0], 5),  53.389,  'L value is good');
is( round_decimals( $val->[1], 5),       0,  'C value is good');
is( round_decimals( $val->[2], 5), 247.099,  'H value is good');

$val = $space->normalize( [53.389, 0, 247.099] );
is( int @$val,                               3,  'normalized gray');
is( round_decimals( $val->[0], 5),      .53389,  'L value good');
is( round_decimals( $val->[1], 5),           0,  'C value good');
is( round_decimals( $val->[2], 5),     0.68639,  'H value good');

$lch = $space->convert_from( 'LAB',  [ .53389, .5, .5]);
is( int @$lch,                          3,  'deconverted gray from LAB');
is( round_decimals( $lch->[0], 5), .53389,  'L value is good');
is( round_decimals( $lch->[1], 5),      0,  'C value is good');
is( round_decimals( $lch->[2], 5),      0,  'H value is good');

$lab = $space->convert_to( 'LAB',  [ .53389, 0, 0.686386111 ]);
is( int @$lab,                          3,  'converted gray to LAB');
is( round_decimals( $lab->[0], 5), .53389,  'L value is good');
is( round_decimals( $lab->[1], 5), .5,  'u value is good');
is( round_decimals( $lab->[2], 5), .5,  'v value is good');

# red
$val = $space->denormalize( [.53389, 0.193974026, .111108333] );
is( int @$val,                            3,  'denormalized red');
is( round_decimals( $val->[0], 5),   53.389,  'L value is good');
is( round_decimals( $val->[1], 5),  104.552,  'C value is good');
is( round_decimals( $val->[2], 5),   39.999,  'H value is good');

$val = $space->normalize( [53.389, 104.552, 39.999] );
is( int @$val,                            3,  'normalized red');
is( round_decimals( $val->[0], 5),   .53389,  'L value good');
is( round_decimals( $val->[1], 5),  0.19397,  'C value good');
is( round_decimals( $val->[2], 5),  0.11111,  'H value good');

$lch = $space->convert_from( 'LAB',  [ .53389, .580092, .6680075]);
is( int @$lch,                         3,  'deconverted red from LAB');
is( round_decimals( $lch->[0], 5), .53389,  'L value good');
is( round_decimals( $lch->[1], 5), .19397,  'C value good');
is( round_decimals( $lch->[2], 5), .11111,  'H value good');

$lab = $space->convert_to( 'LAB',  [ .53389, 0.193974026, .111108333 ]);
is( int @$lab,                         3,  'converted red to LAB');
is( round_decimals( $lab->[0], 5),  .53389,  'L value good');
is( round_decimals( $lab->[1], 5),  .58009,  'u value good');
is( round_decimals( $lab->[2], 5),  .66801,  'v value good');

# blue
$val = $space->denormalize( [.32297, 0.248252319, .850791667] );
is( int @$val,                            3,  'denormalized blue');
is( round_decimals( $val->[0], 5),   32.297,  'L value is good');
is( round_decimals( $val->[1], 5),  133.808,  'C value is good');
is( round_decimals( $val->[2], 5),  306.285,  'H value is good');

$val = $space->normalize( [32.297, 133.808, 306.285] );
is( int @$val,                         3,  'normalized blue');
is( round_decimals( $val->[0], 5), .32297,  'L value good');
is( round_decimals( $val->[1], 5), .24825,  'C value good');
is( round_decimals( $val->[2], 5), .85079,  'H value good');

$lch = $space->convert_from( 'LAB',  [ .32297, .579188, .23035]);
is( int @$lch,                          3,  'deconverted blue from LAB');
is( round_decimals( $lch->[0], 5), .32297,  'L value good');
is( round_decimals( $lch->[1], 5), .24825,  'C value good');
is( round_decimals( $lch->[2], 5), .85079,  'H value good');

$lab = $space->convert_to( 'LAB',  [ .32297, 0.248252319, .850791667 ]);
is( int @$lab,                         3,  'converted blue to LAB');
is( round_decimals( $lab->[0], 5),  .32297,  'L value good');
is( round_decimals( $lab->[1], 5),  .57919,  'u value good');
is( round_decimals( $lab->[2], 5),  .23035,  'v value good');

# mid blue
$val = $space->denormalize( [.37478, 0.220141002, .842422222] );
is( int @$val,                           3,  'denormalized mid blue');
is( round_decimals( $val->[0], 5),  37.478,  'L value is good');
is( round_decimals( $val->[1], 5), 118.656,  'C value is good');
is( round_decimals( $val->[2], 5), 303.272,  'H value is good');

$val = $space->normalize( [37.478, 118.656, 303.272] );
is( int @$val,                          3,  'normalized mid blue');
is( round_decimals( $val->[0], 5), .37478,  'L value good');
is( round_decimals( $val->[1], 5), .22014,  'C value good');
is( round_decimals( $val->[2], 5), .84242,  'H value good');

$lch = $space->convert_from( 'LAB',  [ .37478, .565097, .2519875]);
is( int @$lch,                          3,  'deconverted mid blue from LAB');
is( round_decimals( $lch->[0], 5), .37478,  'L value good');
is( round_decimals( $lch->[1], 5), .22014,  'C value good');
is( round_decimals( $lch->[2], 5), .84242,  'H value good');

$lab = $space->convert_to( 'LAB',  [ .37478, 0.220141002, .842422222 ]);
is( int @$lab,                         3,  'converted mid blue to LAB');
is( round_decimals( $lab->[0], 5),  .37478,  'L value good');
is( round_decimals( $lab->[1], 4),  .5651,  'u value good');
is( round_decimals( $lab->[2], 5),  .25199,  'v value good');

exit 0;
