#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 95;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

my $module = 'Graphics::Toolkit::Color::Space::Instance::OKLCH';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                         'OKLCH', 'color space name is OKLCH');
is( $space->alias,                             '', 'color space has no alias name');
is( $space->is_name('OKlch'),                   1, 'color space name OKlch is correct, lc chars at will!');
is( $space->is_name('LCH'),                     0, 'color space name LCH is given to CIELCHab');
is( $space->axis_count,                         3, 'OKLCH has 3 dimensions');
is( $space->is_euclidean,                       0, 'OKLCH is not euclidean');
is( $space->is_cylindrical,                     1, 'OKLCH is cylindrical');

is( ref $space->check_value_shape([0,0]),              '',   "OKLCH got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "OKLCH got too many values");
is( ref $space->check_value_shape([0, 0, 0]),  'ARRAY',   'check minimal OKLCH values are in bounds');
is( ref $space->check_value_shape([1, 0.5, 360]), 'ARRAY',   'check maximal OKLCH values are in bounds');
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_value_shape([1.01, 0, 0]),       '',   'L value is too big');
is( ref $space->check_value_shape([0, -0.51, 0]),      '',   "c value is too small");
is( ref $space->check_value_shape([0, 0.51, 0]),       '',   'c value is too big');
is( ref $space->check_value_shape([0, 0, -0.1]),       '',   'h value is too small');
is( ref $space->check_value_shape([0, 0, 360.2] ),     '',   "h value is too big");

is( $space->is_value_tuple([0,0,0]),                      1, 'tuple has 3 elements');
is( $space->is_partial_hash({c => 1, h => 0}),            1, 'found hash with some axis names');
is( $space->is_partial_hash({l => 1, c => 0, h => 0}),    1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, 'h*' => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'OKLAB'),                        1, 'do only convert from and to OKLAB');
is( $space->can_convert( 'Lab'),                          0, 'namespace can be written lower case');
is( $space->can_convert( 'CIELCHab'),                     0, 'can not convert to itself');
is( $space->format([1.23,0,41], 'css_string'), 'oklch(1.23, 0, 41)', 'can format css string');

my $val = $space->deformat(['OKLCH', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
$val = $space->deformat(['OKLCH', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'space name (short) was recognized in named ARRAY format');
is( $space->format([0,11,350], 'css_string'), 'oklch(0, 11, 350)', 'can format css string');


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

my $lch = $space->convert_from( 'OKLAB',  [ 0, 0.5, 0.5]);
is( ref $lch,                    'ARRAY',  'deconverted "black" from OKLAB');
is( int @$lch,                         3,  'right amount of values');
is( round_decimals( $lch->[0], 5),     0,  'L value is good');
is( round_decimals( $lch->[1], 5),     0,  'C value is good');
is( round_decimals( $lch->[2], 5),     0,  'H value is good');

my $lab = $space->convert_to( 'OKLAB',  [ 0, 0, 0 ]);
is( ref $lab,                    'ARRAY',  'converted "black" to OKLAB');
is( int @$lab,                         3,  'right amount of values');
is( round_decimals( $lab->[0], 5),     0,  'L value is good');
is( round_decimals( $lab->[1], 5),   0.5,  'a value is good');
is( round_decimals( $lab->[2], 5),   0.5,  'b value is good');

# white
$lch = $space->convert_from( 'OKLAB',  [ 1, 0.5, 0.5]);
is( int @$lch,                        3,  'deconverted white from OKLAB');
is( round_decimals( $lch->[0], 5),    1,  'L value is good');
is( round_decimals( $lch->[1], 5),    0,  'C value is good');
is( round_decimals( $lch->[2], 5),    0,  'H value is good');

$lab = $space->convert_to( 'OKLAB',  [ 1, 0, 0 ]);
is( int @$lab,                      3,  'converted white to LAB');
is( round_decimals( $lab->[0], 5),  1,  'L value is good');
is( round_decimals( $lab->[1], 5), .5,  'u value is good');
is( round_decimals( $lab->[2], 5), .5,  'v value is good');

# gray
$lch = $space->convert_from( 'OKLAB',  [ 0.59987, .5, .5]);
is( int @$lch,                          3,  'deconverted gray from OKLAB');
is( round_decimals( $lch->[0], 5), 0.59987,  'L value is good');
is( round_decimals( $lch->[1], 5),      0,  'C value is good');
is( round_decimals( $lch->[2], 5),      0,  'H value is good');

$lab = $space->convert_to( 'OKLAB',  [ .53389, 0, 0 ]);
is( int @$lab,                          3,  'converted gray to OKLAB');
is( round_decimals( $lab->[0], 5), .53389,  'L value is good');
is( round_decimals( $lab->[1], 5), .5,  'u value is good');
is( round_decimals( $lab->[2], 5), .5,  'v value is good');

# red
$lch = $space->convert_from( 'OKLAB',  [ 0.6279553639214311, 0.7248630684262744, 0.625846277330585]);
is( int @$lch,                          3,  'deconverted red from OKLAB');
is( round_decimals( $lch->[0], 5), .62796,  'L value good');
is( round_decimals( $lch->[1], 5), .51537,  'C value good');
is( round_decimals( $lch->[2], 5), .08121,  'H value good');

$lab = $space->convert_to( 'OKLAB',  [ .627955364, 0.515366608, .081205223]);
is( int @$lab,                         3,  'converted red to OKLAB');
is( round_decimals( $lab->[0], 5),  .62796,  'L value good');
is( round_decimals( $lab->[1], 5),  .72486,  'u value good');
is( round_decimals( $lab->[2], 5),  .62585,  'v value good');

# blue
$lch = $space->convert_from( 'OKLAB',  [ 0.45201371817442365, 0.467543025, 0.188471834]);
is( int @$lch,                          3,  'deconverted blue from OKLAB');
is( round_decimals( $lch->[0], 5), .45201,  'L value good');
is( round_decimals( $lch->[1], 5), .62643,  'C value good');
is( round_decimals( $lch->[2], 5), .73348,  'H value good');

$lab = $space->convert_to( 'OKLAB',  [ .45201371817442365, 0.626428778, .733477841 ]);
is( int @$lab,                         3,  'converted blue to OKLAB');
is( round_decimals( $lab->[0], 5),  .45201,  'L value good');
is( round_decimals( $lab->[1], 5),  .46754,  'u value good');
is( round_decimals( $lab->[2], 5),  .18847,  'v value good');

# green
$lch = $space->convert_from( 'OKLAB',  [ 0.5197518313867289, 0.359697668398572, 0.60767587690661445]);
is( int @$lch,                          3,  'deconverted green from OKLAB');
is( round_decimals( $lch->[0], 5), .51975,  'L value good');
is( round_decimals( $lch->[1], 5), .35372,  'C value good');
is( round_decimals( $lch->[2], 5), .39582,  'H value good');

$lab = $space->convert_to( 'OKLAB',  [ .5197518313867289, 0.353716489, .395820403 ]);
is( int @$lab,                         3,  'converted green to OKLAB');
is( round_decimals( $lab->[0], 5),  .51975,  'L value good');
is( round_decimals( $lab->[1], 5),  .3597,  'u value good');
is( round_decimals( $lab->[2], 5),  .60768,  'v value good');

exit 0;
