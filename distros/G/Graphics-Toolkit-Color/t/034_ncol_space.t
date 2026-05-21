#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 61;

my $module = 'Graphics::Toolkit::Color::Space::Instance::NCol';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space,   'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                            'NCOL', 'color space has user set name');
is( $space->name('alias'),                       '', 'color space has no alias name');
is( $space->is_name('NCol'),                      1, 'color space name NCol is correct');
is( $space->is_name('hwb'),                       0, 'axis initials do not equal space name this time');
is( $space->is_axis_name('ncol'),                 0, 'space name is not axis name');
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
is( $space->is_euclidean,                         0, 'NCol is not euclidean');
is( $space->is_cylindrical,                       1, 'NCol is cylindrical');
is( $space->shape->has_constraints,               1, 'NCol is actually a cone');

is( $space->is_value_tuple([0,0,0]),            1, 'value tuple has 3 elements');
is( $space->is_partial_hash({whiteness => 1, blackness => 0}), 1, 'found hash with some axis name');
is( $space->is_partial_hash({what => 1, blackness => 0}), 0, 'found hash with a bad axis name');
is( $space->can_convert('rgb'),                 1, 'do only convert from and to rgb');
is( $space->can_convert('ncol'),                0, 'can not convert to itself');

is( ref $space->check_value_shape([0, 0, 0]),     'ARRAY', 'check NCol values works on lower bound values');
is( ref $space->check_value_shape([600,100,100]),      '', 'got constraint violation');
is( ref $space->check_value_shape([600, 50, 50]), 'ARRAY', 'check NCol values works on upper bound values');
is( ref $space->check_value_shape([0,0]),              '', "NCol got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '', "NCol got too many values");
is( ref $space->check_value_shape([-1, 0, 0]),         '', "hue value is too small");
is( ref $space->check_value_shape([1.1, 0, 0]),        '', "hue is not integer");
is( ref $space->check_value_shape([601, 0, 0]),        '', "hue value is too big");
is( ref $space->check_value_shape([0, -1, 0]),         '', "whiteness value is too small");
is( ref $space->check_value_shape([0, 1.1, 0]),        '', "whiteness value is not integer");
is( ref $space->check_value_shape([0, 101, 0]),        '', "whiteness value is too big");
is( ref $space->check_value_shape([0, 0, -1 ] ),       '', "blackness value is too small");
is( ref $space->check_value_shape([0, 0, 1.1] ),       '', "blackness value is not integer");
is( ref $space->check_value_shape([0, 0, 101] ),       '', "blackness value is too big");

is( $space->format([0,0,0], 'css_string'),     'ncol(R0, 0%, 0%)',       'can format css string with zeroes');
is( $space->format([212,34,56], 'css_string'), 'ncol(G12, 34%, 56%)', 'can format css string');
is( $space->format([600, 100, 0], 'css_string'),      'ncol(R0, 100%, 0%)', 'converted tuple into css string');
is( $space->format([600, 100, 0], 'css_string', ''),  'ncol(R0, 100, 0)',  'converted tuple into css string without suffixes');

my $ncol = $space->deformat('ncol(R00, 0%, 0%)');
is_tuple( $ncol, [0, 0, 0], [qw/hue whiteness blackness/], 'deformat CSS string with suffix "%"  and leading zero in hue');

$ncol = $space->deformat('ncol(R0, 0%, 0%)');
is_tuple( $ncol, [0, 0, 0], [qw/hue whiteness blackness/], 'deformat CSS string with suffix "%"');
$ncol = $space->deformat('NCOL: G12, 34%, 56%');
is_tuple( $ncol, [212, 34, 56], [qw/hue whiteness blackness/], 'deformat CSS string without suffix "%"');
$ncol = $space->deformat('ncol(G12, 34%, 56.1%)');
is( ref $ncol, '', 'can not deformat with CSS string with ill formatted values');
$ncol = $space->deformat(['NCol', 'B20', '31%', '15']);
is_tuple( $ncol, [420, 31, 15], [qw/hue whiteness blackness/], 'deformat named ARRAY');

$ncol = $space->clamp([700, -1.1, 101]);
is_tuple( $ncol, [100, 0, 100], [qw/hue whiteness blackness/], 'clamped tuple values into range');

$ncol = $space->round([1,22.5, 11.111111]);
is_tuple( $ncol, [1, 23, 11], [qw/hue whiteness blackness/], 'round tuple values');

my $rgb = $space->convert_to( 'RGB', [0.83333, 0, 1]); # should become black despite color value
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], 'convert black to RGB');
$ncol = $space->convert_from( 'RGB', [ 0, 0, 0]);
is_tuple( $ncol, [0, 0, 1], [qw/hue whiteness blackness/], 'convert black from RGB');

$rgb = $space->convert_to( 'RGB', [0, 0.5, .5]);
is_tuple( $rgb, [0.5, 0.5, 0.5], [qw/red green blue/], 'convert grey to RGB');
$ncol = $space->convert_from( 'RGB', [ .5, .5, .5]);
is_tuple( $ncol, [0, .5, .5], [qw/hue whiteness blackness/], 'convert grey from RGB');

$ncol = $space->convert_from( 'RGB', [210/255, 20/255, 70/255]);
is_tuple( $space->round( $ncol, 5), [0.95614, 0.07843, 0.17647], [qw/hue whiteness blackness/], 'convert nice magenta from RGB');
$rgb = $space->convert_to( 'RGB', [0.956140350877193, 0.0784313725490196, 0.176470588235294]);
is_tuple( $space->round( $rgb, 5), [0.82353, 0.07843, 0.27451], [qw/red green blue/], 'convert nice magenta to RGB');

exit 0;
