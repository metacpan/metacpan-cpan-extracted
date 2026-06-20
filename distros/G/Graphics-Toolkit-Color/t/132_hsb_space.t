#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 55;

my $module = 'Graphics::Toolkit::Color::Space::Instance::HSB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space,   'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                             'HSB', 'color space has initials as name');
is( $space->family,                           'HSV', 'color space belongs to the HSL family');
is( $space->name('alias'),                       '', 'color space has no alias name');
is( $space->is_name('HsB'),                       1, 'recognized name');
is( $space->is_name('Hsl'),                       0, 'ignored wrong name');
is( $space->is_axis_name('hsb'),                  0, 'space name is not axis name');
is( $space->is_axis_name('hue'),                  1, '"hue" is an axis name');
is( $space->is_axis_name('saturation'),           1, '"saturation" is an axis name');
is( $space->is_axis_name('brightness'),           1, '"brightness" is an axis name');
is( $space->is_axis_name('h'),                    1, '"h" is an axis name');
is( $space->is_axis_name('s'),                    1, '"s" is an axis name');
is( $space->is_axis_name('b'),                    1, '"b" is an axis name');
is( $space->is_axis_name('hu'),                   0, 'can not miss  lettter of axis name');
is( $space->pos_from_axis_name('hue'),            0, '"hue" is name of first axis');
is( $space->pos_from_axis_name('saturation'),     1, '"saturation" is name of second axis');
is( $space->pos_from_axis_name('brightness'),     2, '"brightness" is name of third axis');
is( $space->pos_from_axis_name('h'),              0, '"h" is name of first axis');
is( $space->pos_from_axis_name('s'),              1, '"s" is name of second axis');
is( $space->pos_from_axis_name('b'),              2, '"b" is name of third axis');
is( $space->pos_from_axis_name('a'),          undef, '"a" is not an axis name');
is( $space->axis_count,                           3, 'color space has 3 axis');
is( $space->is_euclidean,                         0, 'HSB is not euclidean');
is( $space->is_cylindrical,                       1, 'HSB is cylindrical');
is( $space->shape->has_constraints,               1, 'HSB is a cone');
is( $space->can_convert('RGB'),                   1, 'do only convert from and to rgb');

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
is_tuple( $hsb, [0, 0, 0], [qw/hue saturation brightness/], 'clamping empty tuple ceates default color: black');
$hsb = $space->clamp([0, 0]);
is_tuple( $hsb, [0, 0, 0], [qw/hue saturation brightness/], 'clamp inserted zero for missing value');
$hsb = $space->clamp([0, 0, 0, 10]);
is_tuple( $hsb, [0, 0, 0], [qw/hue saturation brightness/], 'clamp removed superfluous value');
$hsb = $space->clamp([0, 100, 0]);
is_tuple( $hsb, [0, 0, 0], [qw/hue saturation brightness/], 'contraints do clamp saturation down');
$hsb = $space->clamp([-1.1, -1, 101]);
is_tuple( $hsb, [358.9, 0, 100], [qw/hue saturation brightness/], 'clamping of brightnesss works');

$hsb = $space->convert_from( 'RGB', [0.5, 0.5, 0.5]);
is_tuple( $hsb, [0, 0, 0.5], [qw/hue saturation brightness/], 'convert grey from RGB');
my $rgb = $space->convert_to( 'RGB', [0, 0, 0.5]);
is_tuple( $rgb, [0.5, 0.5, 0.5], [qw/red green blue/], 'convert grey back to RGB');

$hsb = $space->convert_from( 'RGB', [0, 0, 0]);
is_tuple( $hsb, [0, 0, 0], [qw/hue saturation brightness/], 'convert black from RGB');
$rgb = $space->convert_to( 'RGB', [0, 0, 0]);
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], 'convert black back to RGB');

$hsb = $space->convert_from( 'RGB', [1, 1, 1]);
is_tuple( $hsb, [0, 0, 1], [qw/hue saturation brightness/], 'convert white from RGB');
 $rgb = $space->convert_to( 'RGB', [0, 0, 1]);
is_tuple( $rgb, [1, 1, 1], [qw/red green blue/], 'convert white back to RGB');

$hsb = $space->convert_from( 'RGB', [0.78, 0.078, 0.195000000023]);
is_tuple( $space->round( $hsb, 5), [0.97222, 0.9, 0.78], [qw/hue saturation brightness/], 'convert nice red from RGB');
$rgb = $space->convert_to( 'RGB', [0.972222222, 0.9, 0.78]);
is_tuple( $space->round( $rgb, 5), [0.78, 0.078, 0.195], [qw/red green blue/], 'convert nice red back to RGB');

$hsb = $space->convert_from( 'RGB', [0.160312032, 0.0408, .24]);
is_tuple( $space->round( $hsb, 5), [0.76666, 0.83, 0.24], [qw/hue saturation brightness/], 'convert dark viole from RGB');
$rgb = $space->convert_to( 'RGB', [0.76666, .83, .24]);
is_tuple( $space->round( $rgb, 5), [0.16031, 0.0408, 0.24], [qw/red green blue/], 'convert dark viole back to RGB');

exit 0;
