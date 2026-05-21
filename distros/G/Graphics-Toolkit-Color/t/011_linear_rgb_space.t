#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 63;

my $module = 'Graphics::Toolkit::Color::Space::Instance::RGBLinear';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $space->name,                     'LINEARRGB', 'color space has right name');
is( $space->name(undef,'given'),      'LinearRGB', 'got original name');
is( $space->name('alias'),               'LINRGB', 'color space has alias name "LINRGB"');
is( $space->name('alias','g'),           'linRGB', 'original alias name');
is( $space->is_name('linear RGB'),              1, 'one way to write the space name');
is( $space->is_name('RGB'),                     0, 'SRGB is not linear SRGB');
is( $space->is_axis_name('RGB'),                0, 'space name is not axis name');
is( $space->is_axis_name('Red'),                1, '"red" is an axis name');
is( $space->is_axis_name('gREEN'),              1, '"green" is an axis name');
is( $space->is_axis_name('blue'),               1, '"blue" is an axis name');
is( $space->is_axis_name('ed'),                 0, 'can not miss a lettter of axis name');
is( $space->is_axis_name('R'),                  1, '"r" is an axis name');
is( $space->is_axis_name('g'),                  1, '"g" is an axis name');
is( $space->is_axis_name('b'),                  1, '"b" is an axis name');
is( $space->pos_from_axis_name('red'),          0, '"red" is name of first axis');
is( $space->pos_from_axis_name('green'),        1, '"green" is name of second axis');
is( $space->pos_from_axis_name('blue'),         2, '"blue" is name of third axis');
is( $space->pos_from_axis_name('r'),            0, '"r" is name of first axis');
is( $space->pos_from_axis_name('g'),            1, '"g" is name of second axis');
is( $space->pos_from_axis_name('b'),            2, '"b" is name of third axis');
is( $space->pos_from_axis_name('ed'),       undef, '"ed" is not an axis name');
is( $space->axis_count,                         3, 'lin RGB color space has 3 axis');
is( $space->is_euclidean,                       1, 'lin RGB is euclidean');
is( $space->is_cylindrical,                     0, 'lin RGB is not cylindrical');
is( $space->can_convert('rgb'),                 1, 'do only convert from and to rgb');
is( $space->can_convert('LinearRGB'),           0, 'do not convert from and to itself');

is( $space->is_value_tuple([0,0,0]),                   1,  'RGB tuple has 3 elements');
is( $space->is_number_tuple([-1, 2.3, 5.1e-04]),       1,  'RGB tuple has 3 numbers');
is( $space->can_convert('rgb'),                        1,  'do only convert from and to rgb');
is( $space->can_convert('RGB'),                        1,  'color space name can be written upper case');
is( $space->can_convert('A98RGB'),                     0,  'does not convert directly to Adobe RGB');
is( $space->is_partial_hash({r => 1, b => 0, g=>0}),   1,  'found hash with some short axis names as keys');
is( $space->is_partial_hash({green => 1, blue => 0}),  1,  'found hash with some other long axis names as keys');
is( $space->is_partial_hash({green => 1, cyan => 0}),  0,  'some axis name match some do not');

is( ref $space->check_value_shape( [0,0,0]),    'ARRAY', 'check LRGB values works on lower bound values');
is( ref $space->check_value_shape( [1, 1, 1]),  'ARRAY', 'check LRGB values works on upper bound values');
is( ref $space->check_value_shape( [0,0]),           '', "LRGB got too few values");
is( ref $space->check_value_shape( [0, 0, 0, 0]),    '', "LRGB got too many values");
is( ref $space->check_value_shape( [-0.1, 0, 0]),    '', "red value is too small");
is( ref $space->check_value_shape( [1.1, 0, 0]),     '', "reg value is too big");
is( ref $space->check_value_shape( [0, -0.001, 0]),  '', "green value is too small");
is( ref $space->check_value_shape( [0, 1.1, 0]),     '', "green value is too big");
is( ref $space->check_value_shape( [0, 0, -0.1 ] ),  '', "blue value is too small");
is( ref $space->check_value_shape( [0, 0, 1.1] ),    '', "blue value is too big");

my $rgb = $space->deformat( 'lin_rgb(0, 0.1, 1)');
is_tuple( $rgb, [0, 0.1, 1, ], [qw/red green blue/], 'deformat CSS_string');
($rgb, my $name) = $space->deformat([ 33, 44, 55]);
is( $rgb,   undef,     'array format is RGB only');

$rgb = $space->clamp([]);
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], 'clamped empty tuple into default color black');
$rgb = $space->clamp([0, 1]);
is_tuple( $rgb, [0, 1, 0], [qw/red green blue/], 'clamp inserted zero for missing value blue');
$rgb = $space->clamp([-0.1, 2, 0.5, 0.4, 0.5]);
is_tuple( $rgb, [0, 1, 0.5], [qw/red green blue/], 'clamp changes values to min, max and removes superfluous values');

my $d = $space->delta([.1,.2,.3],[.1,.2,.3]);
is_tuple( $d, [0, 0, 0], [qw/red green blue/], 'delta vector between tuple and itself is zero');
$d = $space->delta([0.1,0.2,0.4],[0, 0.5, 1]);
is_tuple( $d, [-0.1, 0.3, 0.6], [qw/red green blue/], 'delta vector between two very different tuple');

my $lrgb = $space->convert_from( 'RGB', [1, 1, 1]);
is_tuple( $space->round( $lrgb, 9), [1, 1, 1], [qw/red green blue/], 'convert white from RGB');
$rgb = $space->convert_to( 'RGB', [1, 1, 1]);
is_tuple( $space->round( $lrgb, 9), [1, 1, 1], [qw/red green blue/], 'convert white back to RGB');

$lrgb = $space->convert_from( 'RGB', [0, 0, 0]);
is_tuple( $space->round( $lrgb, 9), [0, 0, 0], [qw/red green blue/], 'convert black from RGB');
$rgb = $space->convert_to( 'RGB', [0, 0, 0]);
is_tuple( $space->round( $lrgb, 9), [0, 0, 0], [qw/red green blue/], 'convert black back to RGB');

$lrgb = $space->convert_from( 'RGB', [0.5, 0.5, 0.5]);
is_tuple( $space->round( $lrgb, 9), [0.21404114, 0.21404114, 0.21404114], [qw/red green blue/], 'convert gray from RGB');
$rgb = $space->convert_to( 'RGB', [0.21404114, 0.21404114, 0.21404114]);
is_tuple( $space->round( $rgb, 8), [0.5, 0.5, 0.5], [qw/red green blue/], 'convert grey back to RGB');

$rgb = $space->convert_from( 'RGB', [0, 0.01, 1]);
is_tuple( $space->round( $rgb, 9), [0, 0.000773994, 1], [qw/red green blue/], 'convert unclean blue to linear RGB (this space)');
$rgb = $space->convert_to( 'RGB', [0, 0.000773994, 1]);
is_tuple( $space->round( $rgb, 8), [0, 0.01, 1], [qw/red green blue/], 'convertunclean blue back to RGB');

$rgb = $space->convert_from( 'RGB', [1, 0.954687172, 0]);
is_tuple( $space->round( $rgb, 9), [1, 0.9, 0], [qw/red green blue/], 'convert unclean red to linear RGB (this space)');
$rgb = $space->convert_to( 'RGB', [1, 0.9, 0]);
is_tuple( $space->round( $rgb, 9), [1, 0.954687172, 0], [qw/red green blue/], 'convert unclean red to SRGB');

exit 0;
