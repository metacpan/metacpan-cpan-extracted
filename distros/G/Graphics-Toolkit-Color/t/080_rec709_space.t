#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 58;

my $module = 'Graphics::Toolkit::Color::Space::Instance::Rec709';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $space->name,                        'REC709', 'normalized name is : "REC709"');
is( $space->name(undef,'original'),     'Rec.709', 'original name is : "Rec.709"');
is( $space->name('alias'),                'BT709', 'normalized alias name is : "BT709"');
is( $space->name('alias','original'),    'BT.709', 'original alias name is : "BT.709"');
is( $space->is_name('Rec.709'),                 1, 'recognize original name: "Rec.709"');
is( $space->is_name('BT.709'),                  1, 'recognize original alias name: "BT.709"');
is( $space->is_name('LinearRGB'),               0, 'converter source: "LinearRGB" is not name of this space');
is( $space->is_axis_name('REC709'),             0, 'space name is not axis name');
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
is( $space->axis_count,                         3, 'Rec.709 color space has 3 axis');
is( $space->is_euclidean,                       1, 'Rec.709 is euclidean');
is( $space->is_cylindrical,                     0, 'Rec.709 is not cylindrical');

is( $space->is_value_tuple([0,0,0]),                   1,  'tuple has 3 elements');
is( $space->is_number_tuple([1.1,-12.3,.4e-4]),        1,  'tuple has 3 numbers');
is( $space->can_convert('LinearRGB'),                  1,  'does only convert from and to "LinearRGB"');
is( $space->can_convert('RGB'),                        0,  'does not convert to and from RGB directly');
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

($rgb, $name) = $space->deformat('rec.709: 0.2, 0.3, 0.7');
is( $name, 'named_string',     'discovered "named_string" format');
is_tuple( $rgb, [0.2, 0.3, 0.7], [qw/red green blue/], 'got right values out of named string');

$rgb = $space->convert_from( 'LinearRGB', [0, 0, 0]);
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], "convert black from 'LinearRGB'");
my $lrgb = $space->convert_to( 'LinearRGB', [0, 0, 0]);
is_tuple( $space->round($lrgb, 9), [0, 0, 0], [qw/red green blue/], "convert black back to 'LinearRGB'");

$rgb = $space->convert_from( 'LinearRGB', [1, 1, 1]);
is_tuple( $space->round($rgb, 9), [1, 1, 1], [qw/red green blue/], "convert white from 'LinearRGB'");
$lrgb = $space->convert_to( 'LinearRGB', [1, 1, 1]);
is_tuple( $space->round($lrgb, 9), [1, 1, 1], [qw/red green blue/], "convert white back to 'LinearRGB'");

$rgb = $space->convert_from( 'LinearRGB', [.5,.5,.5]);
is_tuple( $space->round($rgb, 9), [.70551509,.70551509,.70551509], [qw/red green blue/], "convert gray from 'LinearRGB'");
$lrgb = $space->convert_to( 'LinearRGB', [.70551509,.70551509,.70551509]);
is_tuple( $space->round($lrgb, 9), [.5,.5,.5], [qw/red green blue/], "convert gray back to 'LinearRGB'");

$rgb = $space->convert_from( 'LinearRGB', [.001,.1,.999]);
is_tuple( $space->round($rgb, [9,9,9]), [.0045,.290939915,.999505314], [qw/red green blue/], "convert deep blue from 'LinearRGB'");
$lrgb = $space->convert_to( 'LinearRGB', [.0045,.290939915,.999505314]);
is_tuple( $space->round($lrgb, [9,9,9]), [.001,.1,.999], [qw/red green blue/], "convert gray deep blue to 'LinearRGB'");

exit 0;
