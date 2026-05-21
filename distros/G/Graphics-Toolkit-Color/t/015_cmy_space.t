#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 44;

my $module = 'Graphics::Toolkit::Color::Space::Instance::CMY';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $space->name,                           'CMY', 'color space has right name');
is( $space->name('alias'),                     '', 'color space has no alias name');
is( $space->is_name('CMY'),                     1, 'asked for right space name');
is( $space->is_name('CMYK'),                    0, 'CMYK is not CMY');
is( $space->is_axis_name('CMY'),                0, 'space name is not axis name');
is( $space->is_axis_name('Cyan'),               1, '"cyan" is an axis name');
is( $space->is_axis_name('magenta'),            1, '"magenta" is an axis name');
is( $space->is_axis_name('yellow'),             1, '"yellow" is an axis name');
is( $space->is_axis_name('agenta'),             0, '"can not miss lettter of axis name');
is( $space->is_axis_name('c'),                  1, '"c" is an axis name');
is( $space->is_axis_name('m'),                  1, '"m" is an axis name');
is( $space->is_axis_name('y'),                  1, '"y" is an axis name');
is( $space->pos_from_axis_name('Cyan'),         0, '"cyan" is name of first axis');
is( $space->pos_from_axis_name('magenta'),      1, '"magenta" is name of second axis');
is( $space->pos_from_axis_name('yellow'),       2, '"yellow" is name of third axis');
is( $space->pos_from_axis_name('c'),            0, '"c" is name of first axis');
is( $space->pos_from_axis_name('m'),            1, '"m" is name of second axis');
is( $space->pos_from_axis_name('y'),            2, '"y" is name of third axis');
is( $space->pos_from_axis_name('a'),        undef, '"a" is not an axis name');
is( $space->axis_count,                         3, 'CMY color space has 3 axis');
is( $space->is_euclidean,                       1, 'CMY is euclidean');
is( $space->is_cylindrical,                     0, 'CMY is not cylindrical');
is( $space->shape->has_constraints,             0, 'CMY is a cube wiht all the edges, no constraints');
is( $space->can_convert('rgb'),                 1, 'do only convert from and to rgb');

is( ref $space->check_value_shape( [0,0,0]),    'ARRAY',   'check CMY values works on lower bound values');
is( ref $space->check_value_shape( [1, 1, 1]),  'ARRAY',   'check CMY values works on upper bound values');
is( ref $space->check_value_shape( [0,0]),           '',   "CMY got too few values");
is( ref $space->check_value_shape( [0, 0, 0, 0]),    '',   "CMY got too many values");
is( ref $space->check_value_shape( [-1, 0, 0]),      '',   "cyan value is too small");
is( ref $space->check_value_shape( [2, 0, 0]),       '',   "cyan value is too big");
is( ref $space->check_value_shape( [0, -1, 0]),      '', "magenta value is too small");
is( ref $space->check_value_shape( [0, 2, 0]),       '', "magenta value is too big");
is( ref $space->check_value_shape( [0, 0, -1] ),     '',  "yellow value is too small");
is( ref $space->check_value_shape( [0, 0, 2] ),      '',  "yellow value is too big");

my ($rgb, $name) = $space->deformat([ 33, 44, 55]);
is( $rgb,   undef,     'array format is RGB only');

my $cmy = $space->clamp([]);
is_tuple( $cmy, [0, 0, 0], [qw/cyan magenta yellow/], 'clamped empty tuple into default color (white)');
$cmy = $space->clamp([0, 1]);
is_tuple( $cmy, [0, 1, 0], [qw/cyan magenta yellow/], 'clamp inserted zero for missing value');
$cmy = $space->clamp([-0.1, 2, 0.5, 0.4, 0.5]);
is_tuple( $cmy, [0, 1, 0.5], [qw/cyan magenta yellow/], 'clamp changes values to min, max and removes superfluous values');

my $d = $space->delta([.2, 0, .2],[.2, 0,.2]);
is_tuple( $d, [0, 0, 0], [qw/cyan magenta yellow/], 'delta vector between tuple and itself is zero');
$d = $space->delta([0.1, 0.2, 0.4],[0, 0.5, 1]);
is_tuple( $d, [-0.1, 0.3, 0.6], [qw/cyan magenta yellow/], 'delta vector between two very different tuple');


$cmy = $space->convert_from( 'RGB', [0, 0.1, 1]);
is_tuple( $cmy, [1, 0.9, 0], [qw/cyan magenta yellow/], 'convert deep blue from RGB to CMY');

$rgb = $space->convert_to( 'RGB', [1, 0.9, 0 ]);
is_tuple( $rgb, [0, 0.1, 1], [qw/red green blue/], 'convert deep red from CMY to RGB');

exit 0;
