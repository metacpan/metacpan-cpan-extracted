#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 50;

my $module = 'Graphics::Toolkit::Color::Space::Instance::ProPhotoRGB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $space->name,           'PROPHOTORGB',         'color space has name: "PROPHOTORGB"');
is( $space->name('alias'),      'ROMMRGB',         'color space has alias name is "ROMMRGB"');
is( $space->is_name('romm RGB'),        1,         'one way to write the space name');
is( $space->is_name('Pro-Photo RGB'),   1,         'another way to write the space name');
is( $space->is_name('RGB'),             0,         'SRGB is not ProPhoto RGB');
is( $space->is_axis_name('ROMMRGB'),    0,         'space name is not axis name');
is( $space->is_axis_name('Red'),        1,         'red is an axis name');
is( $space->is_axis_name('gREEN'),      1,         'green is an axis name');
is( $space->is_axis_name('blue'),       1,         'blue is an axis name');
is( $space->is_axis_name('ed'),         0,         'can not miss  lettter of axis name');
is( $space->axis_count,                 3,         'lin RGB color space has 3 axis');
is( $space->is_euclidean,               1,         'lin RGB is euclidean');
is( $space->is_cylindrical,             0,         'lin RGB is not cylindrical');

is( $space->is_value_tuple([0,0,0]),                   1,  'vector has 3 elements');
is( $space->can_convert('XYZ'),                        1,  'do only convert from and to rgb');
is( $space->can_convert('xyz'),                        1,  'color space name can be written lower case');
is( $space->can_convert('RGB'),                        0,  'does not convert directly to RGB');
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

my $rgb = $space->clamp([]);
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], 'clamped empty tuple into default color (black)');
$rgb = $space->clamp([0, 1]);
is_tuple( $rgb, [0, 1, 0], [qw/red green blue/], 'clamp inserted zero for missing value');
$rgb = $space->clamp([-0.1, 2, 0.5, 0.4, 0.5]);
is_tuple( $rgb, [0, 1, 0.5], [qw/red green blue/], 'clamp changes values to min, max and removes superfluous values');

($rgb, my $name) = $space->deformat([ 33, 44, 55]);
is( $rgb,    undef,     'array format is RGB only');
($rgb, $name) = $space->deformat('pro_photo_rgb: 0.2, 0.3, 0.7');
is( $name, 'named_string',     "recognized 'named_string' format");
is_tuple( $rgb, [0.2, 0.3, 0.7], [qw/red green blue/], "got values out of 'named_string'");
($rgb, $name) = $space->deformat('romm-rgb(0, 1, 0.7)');
is( $name, 'css_string',     "recognized 'CSS_string' format with alias space name");
is_tuple( $rgb, [0, 1, 0.7], [qw/red green blue/], "got values out of 'CSS_string'");

my $d = $space->delta([.2,.2,.2],[.2,.2,.2]);
is_tuple( $d, [0, 0, 0], [qw/red green blue/], "delta vector of a tuple with itself is zero");
$d = $space->delta([0.1,0.2,0.4],[0, 0.5, 1]);
is_tuple( $d, [-0.1, 0.3, 0.6], [qw/red green blue/], "correct delta vector between two tuple");

$rgb = $space->convert_from( 'XYZ', [0, 0, 0]);
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], "convert black from XYZ");
my $xyz = $space->convert_to( 'XYZ', [0, 0, 0]);
is_tuple( $space->round($xyz, 9), [0, 0, 0], [qw/X Y Z/], "convert black back to XYZ");

$rgb = $space->convert_from( 'XYZ', [1, 1, 1]);
is_tuple( $space->round($rgb, [7, 7, 7]), [1, 1, 1], [qw/red green blue/], "convert white from XYZ");
$xyz = $space->convert_to( 'XYZ', [1, 1, 1]);
is_tuple( $space->round($xyz, [7, 6, 7]), [1, 1, 1], [qw/X Y Z/], "convert white back to XYZ");

$rgb = $space->convert_from( 'XYZ', [1, 0.9, 0]);
is_tuple( $space->round($rgb, [9, 9, 9]), [1.07177559, 0.903644813, 0.057048425], [qw/red green blue/], "convert deep yellow from XYZ");
$xyz = $space->convert_to( 'XYZ', [1.07177559, 0.903644813, 0.057048425]);
is_tuple( $space->round($xyz, [9, 9, 9]), [1, 0.9, 0], [qw/X Y Z/], "convert deep yellow back to XYZ");

$rgb = $space->convert_from( 'XYZ', [0.1, 0.01, 0.95]);
is_tuple( $space->round($rgb, [9, 8, 8]), [0.13191899, -0.10595116, 0.967296], [qw/red green blue/], "convert deep blue from XYZ");
$xyz = $space->convert_to( 'XYZ', [0.13191899, -0.105951156, 0.967296]);
is_tuple( $space->round($xyz, [9, 9, 8]), [0.1, 0.01, 0.95], [qw/X Y Z/], "convert deep blue back to XYZ");

exit 0;
