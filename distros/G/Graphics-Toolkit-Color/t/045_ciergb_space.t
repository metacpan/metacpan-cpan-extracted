#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 55;

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIERGB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $space->name,                        'CIERGB', 'color space has right name');
is( $space->name('alias'),                     '', 'color space has no alias name');
is( $space->is_name('CIE_RGB'),                 1, 'one way to write the space name');
is( $space->is_name('RGB'),                     0, 'CIERGB is not RGB');
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
is( $space->pos_from_axis_name('a'),        undef, '"a" is not an axis name');
is( $space->axis_count,                         3, 'CIERGB color space has 3 axis');
is( $space->is_euclidean,                       1, 'CIERGB is euclidean');
is( $space->is_cylindrical,                     0, 'CIERGB is not cylindrical');

is( $space->is_value_tuple([0,0,0]),                   1,  'tuple has 3 elements');
is( $space->is_number_tuple([0.23,2e-1,0]),            1,  'tuple has 3 numbers');
is( $space->can_convert('xyz'),                        1,  'do only convert from and to CIEXYZ');
is( $space->can_convert('XYZ'),                        1,  'color space name can be written upper case');
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

my ($rgb, $name) = $space->deformat([ 33, 44, 55]);
is( $rgb,   undef,     'array format is RGB only');

my $d = $space->delta([.2,.2,.2],[.2,.2,.2]);
is_tuple( $d, [0, 0, 0], [qw/red green blue/], 'dela vector between color and itself is zero tuple');
$d = $space->delta([0.1,0.2,0.4],[0, 0.5, 1]);
is_tuple( $d, [-.1, 0.3, 0.6], [qw/red green blue/], 'dela vector between two colors');

$rgb = $space->clamp([]);
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], 'clamp on emty tuple creates deafault color black');
$rgb = $space->clamp([0, 1]);
is_tuple( $rgb, [0, 1, 0], [qw/red green blue/], 'clamp inserted missing value as zero');
$rgb = $space->clamp([0, 1, 0.5, 0.4, 0.5]);
is_tuple( $rgb, [0, 1, 0.5], [qw/red green blue/], 'clamp removed superfluous values');
$rgb = $space->clamp([-0.1, 2, 0.5]);
is_tuple( $rgb, [0, 1, 0.5], [qw/red green blue/], 'clamp moved values into range');

$rgb = $space->convert_from( 'XYZ', [0, 0, 0]);
is_tuple( $space->round( $rgb, 9), [0, 0, 0], [qw/red green blue/], 'convert black from XYZ');
my $xyz = $space->convert_to( 'XYZ', [0, 0, 0]);
is_tuple( $space->round( $xyz, 9), [0, 0, 0], [qw/X Y Z/], 'convert black back to XYZ');

$rgb = $space->convert_from( 'XYZ', [1, 1, 1]);
is_tuple( $space->round( $rgb, [9,9,6]), [1, 1, 1], [qw/red green blue/], 'convert white from XYZ');
$xyz = $space->convert_to( 'XYZ', [1, 1, 1]);
is_tuple( $space->round( $xyz, 9), [1, 1, 1], [qw/X Y Z/], 'convert white back to from XYZ');

$rgb = $space->convert_from( 'XYZ', [0.1, 0.2, 0.9]);
is_tuple( $space->round($rgb, 8), [-0.36651109, 0.31339548, 0.90604796], [qw/red green blue/], 'convert nice blue from XYZ');
$xyz = $space->convert_to( 'XYZ', [-0.36651109, 0.31339548, 0.90604796]);
is_tuple( $space->round( $xyz, 6), [.1, .2, .9], [qw/X Y Z/], 'convert nice blue  back to from XYZ');

exit 0;
