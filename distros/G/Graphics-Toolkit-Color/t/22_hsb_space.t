#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 60;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::HSB';

my $space = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $space,   'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                             'HSB', 'color space has initials as name');
is( $space->alias,                               '', 'color space has no alias name');
is( $space->is_name('HsB'),                       1, 'recognized name');
is( $space->is_name('Hsl'),                       0, 'ignored wrong name');
is( $space->axis_count,                           3, 'color space has 3 axis');
is( $space->is_euclidean,                         0, 'HSB is not euclidean');
is( $space->is_cylindrical,                       1, 'HSB is cylindrical');

is( ref $space->check_value_shape([0, 0, 0]),     'ARRAY', 'check HSB values works on lower bound values');
is( ref $space->check_value_shape([360,100,100]), 'ARRAY', 'check HSB values works on upper bound values');
is( ref $space->check_value_shape([0,0]),              '', "HSB got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '', "HSB got too many values");
is( ref $space->check_value_shape([-1, 0, 0]),         '', "hue value is too small");
is( ref $space->check_value_shape([1.1, 0, 0]),        '', "hue is not integer");
is( ref $space->check_value_shape([361, 0, 0]),        '', "hue value is too big");
is( ref $space->check_value_shape([0, -1, 0]),         '', "saturation value is too small");
is( ref $space->check_value_shape([0, 1.1, 0]),        '', "saturation value is not integer");
is( ref $space->check_value_shape([0, 101, 0]),        '', "saturation value is too big");
is( ref $space->check_value_shape([0, 0, -1 ] ),       '', "brightness value is too small");
is( ref $space->check_value_shape([0, 0, 1.1] ),       '', "brightness value is not integer");
is( ref $space->check_value_shape([0, 0, 101] ),       '', "brightness value is too big");

my $hsb = $space->clamp([]);
is( int @$hsb,   3,     'clamp added three missing values as zero');
is( $hsb->[0],   0,     'default color is black (H)');
is( $hsb->[1],   0,     'default color is black (S)');
is( $hsb->[2],   0,     'default color is black (B)');
$hsb = $space->clamp([0,100]);
is( int @$hsb,  3,      'added one missing value');
is( $hsb->[0],   0,     'carried first min value');
is( $hsb->[1], 100,     'carried second max value');
is( $hsb->[2],   0,     'set missing color value to zero (B)');
$hsb = $space->clamp([-1.1,-1,101,4]);
is( int @$hsb,  3,     'removed superfluous value');
is( $hsb->[0], 358.9,   'rotated up (H) value and removed decimals');
is( $hsb->[1],   0,     'clamped up too small (S) value');
is( $hsb->[2], 100,     'clamped down too large (B) value');;


$hsb = $space->convert_from( 'RGB', [0.5, 0.5, 0.5]);
is( int @$hsb,   3,     'convert grey to HSB');
is( $hsb->[0],   0,     'right hue value');
is( $hsb->[1],   0,     'right saturation');
is( $hsb->[2],  0.5,    'right brightness');

my $rgb = $space->convert_to( 'RGB', [0, 0, 0.5]);
is( int @$rgb,  3,      'converted grey from HSB to RGB');
is( $rgb->[0], 0.5,     'right red value');
is( $rgb->[1], 0.5,     'right green value');
is( $rgb->[2], 0.5,     'right blue value');

$rgb = $space->convert_to( 'RGB', [0.972222222, 0.9, 0.78]);
is( int @$rgb,                        3, 'convert red from HSB into RGB');
is( $rgb->[0],                     0.78, 'right red value');
is( $rgb->[1],                    0.078, 'right green value');
is( round_decimals($rgb->[2], 5), 0.195, 'right blue value');

$hsb = $space->convert_from( 'RGB', [0.78, 0.078, 0.195000000023]);
is( int @$hsb,        3,  'convert nice blue to HSB');
is( round_decimals($hsb->[0], 5), 0.97222, 'right hue value');
is( $hsb->[1],  .9,      'right saturation');
is( $hsb->[2],  .78,     'right brightness');

$rgb = $space->convert_to( 'RGB', [0.76666, .83, .24]);
is( int @$rgb,                             3,   'convert dark vilet from HSB to RGB');
is( round_decimals($rgb->[0], 5),   0.16031,    'red value correct');
is( round_decimals($rgb->[1], 5),   0.0408,     'green value correct');
is( round_decimals($rgb->[2], 5),   0.24,       'blue value correct');

$hsb = $space->convert_from( 'RGB', [0.160312032, 0.0408, .24]);
is( int @$hsb,                         3,  'convert dark violet from RGB to HSB');
is( round_decimals($hsb->[0], 5),0.76666,  'right hue value');
is( round_decimals($hsb->[1], 5), .83,     'right saturation');
is( round_decimals($hsb->[2], 5), .24,     'right brightness');

is( $space->format([240, 88, 0], 'css_string'),      'hsb(240, 88%, 0%)', 'converted tuple into css string');
is( $space->format([240, 88, 0], 'css_string', ''),  'hsb(240, 88, 0)', 'converted tuple into css string without suffixes');


exit 0;
