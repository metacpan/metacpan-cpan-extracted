#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 58;

my $module = 'Graphics::Toolkit::Color::Space::Instance::DCIP3';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $space->name,                         'DCIP3', 'normalized name is : "DISPLAYP3"');
is( $space->name(undef,'original'),      'DCI-P3', 'original name is : "display-p3"');
is( $space->name('alias'),              'SMPTEP3', 'normalized alias name is : "SMPTEP3"');
is( $space->is_name('DCI P3'),                  1, 'can use widely used space name: "DCI P3"');
is( $space->is_name('SMPTE_P3'),                1, 'alias space name can be written: "SMPTE_P3"');
is( $space->is_name('Display P3 Linear'),       0, 'linear P3 is not P3');
is( $space->is_axis_name('DCIP3'),              0, 'space name is not axis name');
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
is( $space->axis_count,                         3, 'Display P3 color space has 3 axis');
is( $space->is_euclidean,                       1, 'Display P3 is euclidean');
is( $space->is_cylindrical,                     0, 'Display P3 is not cylindrical');

is( $space->is_value_tuple([0,0,0]),                   1,  'tuple has 3 elements');
is( $space->is_number_tuple([1.1,-12.3,.4e-4]),        1,  'tuple has 3 numbers');
is( $space->can_convert('DCI-P3-Linear'),              1,  'do only convert from and to "dci-p3-linear"');
is( $space->can_convert('DCIP3LINEAR'),                1,  'use normalized name of converter parent');
is( $space->can_convert('DisplayP3Linear'),            0,  'Display P3 Linear is different from ');
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

($rgb, $name) = $space->deformat('dci_p3: 0.2, 0.3, 0.7');
is( $name, 'named_string',     'discovered "named_string" format');
is_tuple( $rgb, [0.2, 0.3, 0.7], [qw/red green blue/], 'got right values out of named string');

$rgb = $space->convert_from( 'DCIP3Linear', [0, 0, 0]);
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], "convert black from 'DCI-P3-Linear'");
my $lrgb = $space->convert_to( 'DCIP3Linear', [0, 0, 0]);
is_tuple( $space->round($lrgb, 9), [0, 0, 0], [qw/red green blue/], "convert black back to 'DCI-P3-Linear'");

$rgb = $space->convert_from( 'DCIP3Linear', [1, 1, 1]);
is_tuple( $space->round($rgb, 9), [1, 1, 1], [qw/red green blue/], "convert white from 'DCI-P3-Linear'");
$lrgb = $space->convert_to( 'DCIP3Linear', [1, 1, 1]);
is_tuple( $space->round($lrgb, 9), [1, 1, 1], [qw/red green blue/], "convert white back to 'DCI-P3-Linear'");

$rgb = $space->convert_from( 'DCIP3Linear', [.5,.5,.5]);
is_tuple( $space->round($rgb, 8), [.75311225,.75311225,.75311225], [qw/red green blue/], "convert gray from 'DCI-P3-Linear'");
$lrgb = $space->convert_to( 'DCIP3Linear', [.753112254,.753112254,.753112254]);
is_tuple( $space->round($lrgb, 8), [.5,.5,.5], [qw/red green blue/], "convert gray back to 'DCI-P3-Linear'");

$rgb = $space->convert_from( 'DCIP3Linear', [.001,.1,.999]);
is_tuple( $space->round($rgb, [9,9,9]), [.01292,.380148083,.999594106], [qw/red green blue/], "convert deep blue from 'DCI-P3-Linear'");
$lrgb = $space->convert_to( 'DCIP3Linear', [.01292,.380148083,.999594106]);
is_tuple( $space->round($lrgb, [9,9,8]), [.001,.1,.999], [qw/red green blue/], "convert gray deep blue to 'DCI-P3-Linear'");

exit 0;
