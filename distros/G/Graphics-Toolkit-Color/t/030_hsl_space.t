#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 46;

my $module = 'Graphics::Toolkit::Color::Space::Instance::HSL';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'could load module');
is( $space->name,                           'HSL', 'space has name from axis initials');
is( $space->name('alias'),                     '', 'color space has no alias name');
is( $space->is_name('Hsl'),                     1, 'recognized name');
is( $space->is_name('HSV'),                     0, 'ignored wrong name');
is( $space->is_axis_name('hsl'),                0,  'space name is not axis name');
is( $space->is_axis_name('hue'),                1,  'hue is an axis name');
is( $space->is_axis_name('saturation'),         1,  'saturation is an axis name');
is( $space->is_axis_name('lightness'),          1,  'lightness is an axis name');
is( $space->is_axis_name('h'),                  1,  'h is an axis name');
is( $space->is_axis_name('s'),                  1,  's is an axis name');
is( $space->is_axis_name('l'),                  1,  'l is an axis name');
is( $space->is_axis_name('hu'),                 0,  'can not miss a lettter of axis name');
is( $space->pos_from_axis_name('s'),            1,  'a is the second axis');
is( $space->axis_count,                         3, 'color space has 3 axis');
is( $space->is_euclidean,                       0, 'HSL is not euclidean');
is( $space->is_cylindrical,                     1, 'HSL is cylindrical');
is( $space->shape->has_constraints,             0, 'HWL is a full cylinder');

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
is_tuple( $hsl, [0, 0, 0], [qw/hue saturation lightness/], 'clamping empty tuple ceates default color: black');
$hsl = $space->clamp([0, 100]);
is_tuple( $hsl, [0, 100, 0], [qw/hue saturation lightness/], 'clamp inserted zero for missing value');
$hsl = $space->clamp( [-1, -1, 101, 4]);
is_tuple( $hsl, [359, 0, 100], [qw/hue saturation lightness/], 'clamp moved three values in the right place');

my $d = $space->delta([0.3,0.3,0.3],[0.3,0.4,0.2]);
is_tuple( $d, [ 0, 0.1, -.1 ], [qw/hue saturation lightness/], 'compute delta vector');
$d = $space->delta([0.9,0,0],[0.1,0,1]);
is_tuple( $d, [ .2, 0, 1], [qw/hue saturation lightness/], 'negative hue delta across the cylindrical border');
$d = $space->delta([0.3,0,0],[0.9,0,0]);
is_tuple( $d, [ -.4, 0, 0], [qw/hue saturation lightness/], 'negative hue delta because cylindrical quality of dimension');

$hsl = $space->convert_from( 'RGB', [0, 0, 0]);
is_tuple( $hsl, [0, 0, 0], [qw/hue saturation lightness/], 'convert black from RGB');
my $rgb = $space->convert_to( 'RGB', [0, 0, 0]);
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], 'convert black back to RGB');

$hsl = $space->convert_from( 'RGB', [0.5, 0.5, 0.5]);
is_tuple( $hsl, [0, 0, 0.5], [qw/hue saturation lightness/], 'convert grey from RGB');
$rgb = $space->convert_to( 'RGB', [0, 0, 0.5]);
is_tuple( $rgb, [0.5, 0.5, 0.5], [qw/red green blue/], 'convert grey back to RGB');

$hsl = $space->convert_from( 'RGB', [1, 1, 1]);
is_tuple( $hsl, [0, 0, 1], [qw/hue saturation lightness/], 'convert white from RGB');
$rgb = $space->convert_to( 'RGB', [0, 0, 1]);
is_tuple( $rgb, [1, 1, 1], [qw/red green blue/], 'convert white back to RGB');

$hsl = $space->convert_from( 'RGB', [0.00784, 0.7843, 0.0902]);
is_tuple( $space->round( $hsl, 5), [0.35101, 0.98021, 0.39607], [qw/hue saturation lightness/], 'convert nice green from RGB');
$rgb = $space->convert_to( 'RGB', [0.351011857232397, 0.980205519226399, 0.39607]);
is_tuple( $space->round( $rgb, 6), [0.00784, 0.7843, 0.0902], [qw/red green blue/], 'convert grey back to RGB');

exit 0;
