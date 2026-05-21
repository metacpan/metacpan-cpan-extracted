#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 55;

my $module = 'Graphics::Toolkit::Color::Space::Instance::HWB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                             'HWB', 'color space has axis initials as name');
is( $space->name('alias'),                       '', 'color space has no alias name');
is( $space->is_name('HwB'),                       1, 'recognized name');
is( $space->is_name('Hsl'),                       0, 'ignored wrong name');
is( $space->is_axis_name('hsb'),                  0, 'space name is not axis name');
is( $space->is_axis_name('hue'),                  1, '"hue" is an axis name');
is( $space->is_axis_name('whiteness'),            1, '"whiteness" is an axis name');
is( $space->is_axis_name('blackness'),            1, '"blackness" is an axis name');
is( $space->is_axis_name('h'),                    1, '"h" is an axis name');
is( $space->is_axis_name('w'),                    1, '"w" is an axis name');
is( $space->is_axis_name('b'),                    1, '"b" is an axis name');
is( $space->is_axis_name('hu'),                   0, 'can not miss  lettter of axis name');
is( $space->pos_from_axis_name('hue'),            0, '"hue" is name of first axis');
is( $space->pos_from_axis_name('whiteness'),      1, '"whiteness" is name of second axis');
is( $space->pos_from_axis_name('blackness'),      2, '"blackness" is name of third axis');
is( $space->pos_from_axis_name('h'),              0, '"h" is name of first axis');
is( $space->pos_from_axis_name('w'),              1, '"w" is name of second axis');
is( $space->pos_from_axis_name('b'),              2, '"b" is name of third axis');
is( $space->pos_from_axis_name('a'),          undef, '"a" is not an axis name');
is( $space->axis_count,                           3, 'color space has 3 axis');
is( $space->is_euclidean,                         0, 'HWB is not euclidean');
is( $space->is_cylindrical,                       1, 'HWB is cylindrical');
is( $space->shape->has_constraints,               1, 'HWB is actually a cone');
is( $space->can_convert('RGB'),                   1, 'do only convert from and to RGB');
is( $space->can_convert('CMY'),                   0, 'do not convert from and to CMY');

is( ref $space->check_value_shape([0, 0, 0]),     'ARRAY', 'check HWB values works on lower bound values');
is( ref $space->check_value_shape([360,100,0]),   'ARRAY', 'check HWB values works on upper bound values (max W)');
is( ref $space->check_value_shape([360,0,100]),   'ARRAY', 'check HWB values works on upper bound values (max B)');
is( ref $space->check_value_shape([360,60,60]),        '', 'trigger sace contraints');
is( ref $space->check_value_shape([0,0]),              '', "HWB got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '', "HWB got too many values");
is( ref $space->check_value_shape([-1, 0, 0]),         '', "hue value is too small");
is( ref $space->check_value_shape([1.1, 0, 0]),        '', "hue is not integer");
is( ref $space->check_value_shape([361, 0, 0]),        '', "hue value is too big");
is( ref $space->check_value_shape([0, -1, 0]),         '', "whiteness value is too small");
is( ref $space->check_value_shape([0, 1.1, 0]),        '', "whiteness value is not integer");
is( ref $space->check_value_shape([0, 101, 0]),        '', "whiteness value is too big");
is( ref $space->check_value_shape([0, 0, -1 ] ),       '', "blackness value is too small");
is( ref $space->check_value_shape([0, 0, 1.1] ),       '', "blackness value is not integer");
is( ref $space->check_value_shape([0, 0, 101] ),       '', "blackness value is too big");

my $hwb = $space->form->remove_suffix([qw/360 100% 100%/]);
is_tuple( $hwb, [360, 100, 100], [qw/hue whiteness blackness/], 'removed suffix "%" from last two values');
$hwb = $space->deformat('hwb(240, 88%, 22%)');
is_tuple( $hwb, [240, 88, 22], [qw/hue whiteness blackness/], 'deformated CSS string with suffix');
$hwb = $space->deformat('hwb(240, 88, 22)');
is_tuple( $hwb, [240, 88, 22], [qw/hue whiteness blackness/], 'deformated CSS string without suffix');

is( $space->format([240, 88, 22], 'css_string'),  'hwb(240, 88%, 22%)', 'converted tuple into css string');
is( $space->format([240, 88, 22], 'css_string', ''),  'hwb(240, 88, 22)', 'converted tuple into css string without suffixes');

$hwb = $space->clamp([]);
is_tuple( $hwb, [0, 0, 0], [qw/hue whiteness blackness/], 'clamping empty tuple ceates default color: black');
$hwb = $space->clamp([-10, -80, 180]);
is_tuple( $hwb, [350, 0, 100], [qw/hue whiteness blackness/], 'clamping values into range');

$hwb = $space->round([1,22.5, 11.111111]);
is_tuple( $hwb, [1, 23, 11], [qw/hue whiteness blackness/], "rounded values to int's");

my $rgb = $space->convert_to( 'RGB', [0.83333, 0, 1]); # should become black despite color value
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], "convert black to RGB");

$hwb = $space->convert_from( 'RGB', [ .5, .5, .5]);
is_tuple( $hwb, [0, .5, .5], [qw/hue whiteness blackness/], "convert grey from RGB");

$rgb = $space->convert_to( 'RGB', [0, 0.5, .5]);
is_tuple( $rgb, [0.5, 0.5, 0.5], [qw/red green blue/], "convert grey to RGB");

$hwb = $space->convert_from( 'RGB', [210/255, 20/255, 70/255]);
is_tuple( $space->round($hwb, 5), [0.95614, 0.07843, 0.17647], [qw/hue whiteness blackness/], "convert nice magenta from RGB");

$rgb = $space->convert_to( 'RGB', [0.956140350877193, 0.0784313725490196, 0.176470588235294]);
is_tuple( $space->round($rgb, 5), [0.82353, 0.07843, 0.27451], [qw/red green blue/], "convert nice magenta to RGB");

exit 0;
