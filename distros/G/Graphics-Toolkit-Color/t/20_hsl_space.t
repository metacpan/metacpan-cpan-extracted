#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 63;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::HSL';

my $space = eval "require $module";
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'could load module');
is( $space->name,                           'HSL', 'space has name from axis initials');
is( $space->alias,                             '', 'color space has no alias name');
is( $space->is_name('Hsl'),                     1, 'recognized name');
is( $space->is_name('HSV'),                     0, 'ignored wrong name');
is( $space->axis_count,                         3, 'color space has 3 axis');
is( ref $space->check_value_shape( [0, 0, 0]),     'ARRAY',   'check HSL values works on lower bound values');
is( ref $space->check_value_shape( [360,100,100]), 'ARRAY',   'check HSL values works on upper bound values');
is( ref $space->check_value_shape( [0,0]),              '',   "HSL got too few values");
is( ref $space->check_value_shape( [0, 0, 0, 0]),       '',   "HSL got too many values");
is( ref $space->check_value_shape( [-1, 0, 0]),         '',   "hue value is too small");
is( ref $space->check_value_shape( [1.1, 0, 0]),        '',   "hue is not integer");
is( ref $space->check_value_shape( [361, 0, 0]),        '',   "hue value is too big");
is( ref $space->check_value_shape( [0, -1, 0]),         '',   "saturation value is too small");
is( ref $space->check_value_shape( [0, 1.1, 0]),        '',   "saturation value is not integer");
is( ref $space->check_value_shape( [0, 101, 0]),        '',   "saturation value is too big");
is( ref $space->check_value_shape( [0, 0, -1 ] ),       '',  "lightness value is too small");
is( ref $space->check_value_shape( [0, 0, 1.1] ),       '',  "lightness value is not integer");
is( ref $space->check_value_shape( [0, 0, 101] ),       '',  "lightness value is too big");


my $hsl = $space->clamp([]);
is( int @$hsl,   3,     'missing values are clamped to black (default color)');
is( $hsl->[0],   0,     'default color is black (H)');
is( $hsl->[1],   0,     'default color is black (S)');
is( $hsl->[2],   0,     'default color is black (L)');

$hsl = $space->clamp([0,100]);
is( int @$hsl,   3,     'clamp added missing value');
is( $hsl->[0],   0,     'carried first min value (H)');
is( $hsl->[1], 100,     'carried second max value (S)');
is( $hsl->[2],   0,     'set missing value to zero');

$hsl = $space->clamp( [-1, -1, 101, 4]);
is( int @$hsl,     3,   'clamp removed superfluous value');
is( $hsl->[0],   359,   'rotated up (H) value');
is( $hsl->[1],     0,   'clamped up (S) value');
is( $hsl->[2],   100,   'clamped down(L) value');;



$hsl = $space->convert_from( 'RGB', [0, 0, 0]);
is( ref $hsl,               'ARRAY', 'convert black from RGB to HSL');
is( int @$hsl,                    3, 'tight amount of values');
is( round_decimals($hsl->[0], 5), 0, 'right hue');
is( round_decimals($hsl->[1], 5), 0, 'right saturation');
is( round_decimals($hsl->[2], 5), 0, 'right lightness');

my $rgb = $space->convert_to( 'RGB', [0, 0, 0]);
is( int @$rgb,   3,     'convert black from HSL to RGB');
is( $rgb->[0],   0,     'right red value');
is( $rgb->[1],   0,     'right green value');
is( $rgb->[2],   0,     'right blue value');


$hsl = $space->convert_from( 'RGB', [0.5, 0.5, 0.5]);
is( int @$hsl,   3,     'convert grey from RGB to HSL');
is( $hsl->[0],   0,     'right hue value');
is( $hsl->[1],   0,     'right saturation');
is( $hsl->[2],  0.5,    'right lightness');

$rgb = $space->convert_to( 'RGB', [0, 0, 0.5]);
is( int @$rgb,   3,     'convert grey from HSL to RGB');
is( $rgb->[0], 0.5,     'right red value');
is( $rgb->[1], 0.5,     'right green value');
is( $rgb->[2], 0.5,     'right blue value');

$hsl = $space->convert_from( 'RGB', [0.00784, 0.7843, 0.0902]);
is( int @$hsl,                          3, 'convert nice green from RGB to HSL');
is( round_decimals($hsl->[0], 5), 0.35101, 'right hue value');
is( round_decimals($hsl->[1], 5), 0.98021, 'right saturation');
is( round_decimals($hsl->[2], 5), 0.39607, 'right lightness');

$rgb = $space->convert_to( 'RGB', [0.351011857232397, 0.980205519226399, 0.39607]);
is( int @$rgb,                          3, 'convert nice green from HSL to RGB');
is( round_decimals($rgb->[0], 5), 0.00784, 'right red value');
is( round_decimals($rgb->[1], 5), 0.7843,  'right green value');
is( round_decimals($rgb->[2], 5), 0.0902,  'right blue value');


my $d = $space->delta([0.3,0.3,0.3],[0.3,0.4,0.2]);
is( int @$d,   3,      'delta vector has right length');
is( $d->[0],    0,      'no delta in hue component');
is( $d->[1],    0.1,    'positive delta in saturation component');
is( $d->[2],   -0.1,    'negatve delta in lightness component');

$d = $space->delta([0.9,0,0],[0.1,0,0]);
is( $d->[0],   .2,      'negative delta across the cylindrical border');
$d = $space->delta([0.3,0,0],[0.9,0,0]);
is( $d->[0],  -.4,      'negative delta because cylindrical quality of dimension');

exit 0;
