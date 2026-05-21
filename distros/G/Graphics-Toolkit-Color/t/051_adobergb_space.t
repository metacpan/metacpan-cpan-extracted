#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 41;

my $module = 'Graphics::Toolkit::Color::Space::Instance::AdobeRGB';
my $rgb_axis   = [qw/red green blue/];
my $xyz_axis   = [qw/X Y Z/];

my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $space->name,         'ADOBERGB',              'color space has right name');
is( $space->name('alias'),   'OPRGB',              'color space has alias name: "OPRGB"');
is( $space->is_name('AdobeRGB'),   1,              'one way to write the space name');
is( $space->is_name('opRGB'),      1,              'alias name of the space name');
is( $space->is_name('RGB'),        0,              'Adobe RGB is not standard RGB');
is( $space->axis_count,            3,              'Adobe RGB color space has 3 axis');
is( $space->is_euclidean,          1,              'Adobe RGB is euclidean');
is( $space->is_cylindrical,        0,              'Adobe RGB is not cylindrical');

is( $space->is_value_tuple([0,0,0]),                   1,  'vector has 3 elements');
is( $space->can_convert('CIEXYZ'),                     1,  'normal converter parent, can only convert to and from XYZ');
is( $space->can_convert('CIE_xyz'),                    1,  'converter parent gets normalized');
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
is_tuple( $rgb, [0, 0, 0], $rgb_axis, 'clamp filled in three zeros from empty ARRAY');

$rgb = $space->clamp([0, 1]);
is_tuple( $rgb, [0, 1, 0], $rgb_axis, 'clamp filled in one zero for a missing value');

$rgb = $space->clamp([-0.1, 2, 0.5, 0.4, 0.5]);
is_tuple( $rgb, [0, 1, 0.5], $rgb_axis, 'clamp remove superfluous values and clamped into range');

($rgb, my $name) = $space->deformat([ 33, 44, 55]);
is( $rgb,   undef,     'array format is RGB only');

my $d = $space->delta([.2,.2,.2],[.2,.2,.2]);
is_tuple( $d, [0, 0, 0], $rgb_axis, 'zero delta vector between a tuple and itself');

$d = $space->delta([0.1,0.2,0.4],[0, 0.5, 1]);
is_tuple( $d, [-0.1, 0.3, 0.6], $rgb_axis, 'right delta vector between two very different tuple');

$rgb = $space->convert_from( 'CIEXYZ', [0, 0, 0]);
is_tuple( $rgb, [0, 0, 0], $rgb_axis, 'convert black from XYZ into AdobeRGB');

my $xyz = $space->convert_to( 'CIEXYZ', [0, 0, 0]);
is_tuple( $xyz, [0, 0, 0], $xyz_axis, 'convert black back to XYZ from AdobeRGB');

$rgb = $space->convert_from( 'CIEXYZ', [1, 1, 1]);
is_tuple( $space->round( $rgb, 7), [1, 1, 1], $rgb_axis, 'convert white from XYZ into AdobeRGB');

$xyz = $space->convert_to( 'CIEXYZ', [1, 1, 1]);
is_tuple( $space->round( $xyz, 6), [1, 1, 1], $xyz_axis, 'convert white back to XYZ from AdobeRGB');

$rgb = $space->convert_from( 'CIEXYZ', [1, 0, .1]);
is_tuple( $space->round( $rgb, [9,9,7]), [1.339783394, -0.961239657, 0.3861199], $rgb_axis, 'convert blueish red from XYZ into AdobeRGB');

$xyz = $space->convert_to( 'CIEXYZ', [1.339783394, -0.961239657, 0.386119895]);
is_tuple( $space->round( $xyz, [8,6,6]), [1, 0, .1], $xyz_axis, 'convert back blueish red to XYZ from AdobeRGB');

$rgb = $space->convert_from( 'CIEXYZ', [.1, 0.2, .9]);
is_tuple( $space->round( $rgb, [9,9,9]), [-0.538885961, 0.598851148, 0.987468678], $rgb_axis, 'convert deep blue from XYZ into AdobeRGB');

$xyz = $space->convert_to( 'CIEXYZ', [-0.538885961, 0.598851148, 0.987468678]);
is_tuple( $space->round( $xyz, [7,7,8]), [.1, 0.2, .9], $xyz_axis, 'convert back deep blue to XYZ from AdobeRGB');

exit 0;
