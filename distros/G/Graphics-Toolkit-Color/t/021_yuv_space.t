#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 55;

my $module = 'Graphics::Toolkit::Color::Space::Instance::YUV';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'YUV', 'color space has initials as name');
is( $space->name('alias'),                'YPBPR', 'color space has alias name YCbCr');
is( $space->is_name('YPbPr'),                   1, 'color space name YCbCr is correct');
is( $space->is_name('YUV'),                     1, 'color space name YUV is correct');
is( $space->is_axis_name('YUV'),                0, 'space name is not axis name');
is( $space->is_axis_name('luma'),               1, 'luma is an axis name');
is( $space->is_axis_name('pb'),                 1, 'Pb is an axis name');
is( $space->is_axis_name('Pr'),                 1, 'Pr is an axis name');
is( $space->is_axis_name('y'),                  1, 'y is an axis name');
is( $space->is_axis_name('u'),                  1, 'u is an axis name');
is( $space->is_axis_name('v'),                  1, 'q is an axis name');
is( $space->is_axis_name('inphase'),            0, 'can not miss  lettter of axis name');
is( $space->pos_from_axis_name('y'),            0, 'y is the first axis');
is( $space->pos_from_axis_name('z'),        undef, 'z is not an axis in YUV');
is( $space->axis_count,                         3, 'color space has 3 axis');
is( $space->is_euclidean,                       1, 'YUV is euclidean');
is( $space->is_cylindrical,                     0, 'YUV is not cylindrical');
is( $space->shape->has_constraints,             0, 'YUV is a cube wiht all the edges, no constraints');
is( $space->can_convert('rgb'),                 1, 'do only convert from and to rgb');
is( $space->can_convert('yuv'),                 0, 'can not convert to itself');

is( ref $space->check_value_shape([0, 0, 0]),       'ARRAY', 'check neutral YUV values are in bounds');
is( ref $space->check_value_shape([0, -0.5, -0.5]), 'ARRAY', 'check YUV values works on lower bound values');
is( ref $space->check_value_shape([1, 0.5, 0.5]),   'ARRAY', 'check YUV values works on upper bound values');
is( ref $space->check_value_shape([0,0]),                '', "YUV got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),         '', "YUV got too many values");
is( ref $space->check_value_shape([-1, 0, 0]),           '', "luma value is too small");
is( ref $space->check_value_shape([1.1, 0, 0]),          '', "luma value is too big");
is( ref $space->check_value_shape([0, -.51, 0]),         '', "Cb value is too small");
is( ref $space->check_value_shape([0, .51, 0]),          '', "Cb value is too big");
is( ref $space->check_value_shape([0, 0, -.51] ),        '', "Cr value is too small");
is( ref $space->check_value_shape([0, 0, 0.51] ),        '', "Cr value is too big");

is( $space->is_value_tuple([0,0,0]),            1,  'value vector has 3 elements');
is( $space->is_partial_hash({y => 1, Pb => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({Y => 1, U => 0, V => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({luma => 1, Pb => 0, Pr => 0}), 1, 'found hash with all axis names');
is( $space->is_partial_hash({a => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->format([0,1,2], 'css_string'), 'yuv(0, 1, 2)', 'can format css string');

my $yuv = $space->deformat(['yuv', 1, 0, -0.1]);
is_tuple( $yuv, [1, 0, -0.1], [qw/Y U V/], 'deformat flat named ARRAY');

$yuv = $space->convert_from( 'RGB', [ 0, 0, 0]);
is_tuple( $yuv, [0, 0.5, 0.5], [qw/Y U V/], 'convert black from RGB');

$yuv = $space->denormalize( [0, 0.5, 0.5] );
is_tuple( $yuv, [0, 0, 0], [qw/Y U V/], 'denormalize black in YUV');

$yuv = $space->normalize( [0, 0, 0] );
is_tuple( $yuv, [0, 0.5, 0.5], [qw/Y U V/], 'normalize black in YUV');

my $rgb = $space->convert_to( 'RGB', [0, 0.5, 0.5]);
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], 'convert black to RGB');

$yuv = $space->convert_from( 'RGB', [ 1, 1, 1]);
is_tuple( $yuv, [1, 0.5, 0.5], [qw/Y U V/], 'convert white from RGB');

$yuv = $space->denormalize( [1, 0.5, 0.5] );
is_tuple( $yuv, [1, 0, 0], [qw/Y U V/], 'denormalize white in YUV');

$rgb = $space->convert_to( 'RGB', [1, .5, .5]);
is_tuple( $rgb, [1, 1, 1], [qw/red green blue/], 'convert white to RGB');

$yuv = $space->convert_from( 'RGB', [ .5, .5, .5]);
is_tuple( $yuv, [.5, .5, .5], [qw/Y U V/], 'convert grey from RGB');

$yuv = $space->denormalize( [0.5, 0.5, 0.5] );
is_tuple( $yuv, [.5, 0, 0], [qw/Y U V/], 'denormalize grey in YUV');

$yuv = $space->normalize( [0.5, 0, 0] );
is_tuple( $yuv, [.5, .5, .5], [qw/Y U V/], 'denormalize grey in YUV');

$rgb = $space->convert_to( 'RGB', [.5, .5, .5]);
is_tuple( $rgb, [.5, .5, .5], [qw/red green blue/], 'convert grey to RGB');

$yuv = $space->convert_from( 'RGB', [ 0.11, 0, 1]);
is_tuple( $space->round($yuv, 5), [0.14689, 0.48144+0.5, -0.02631+0.5], [qw/Y U V/], 'convert nice blue from RGB');

$rgb = $space->convert_to( 'RGB', [0.14689, 0.48143904+0.5, -0.026312+0.5]);
is_tuple( $space->round($rgb, 5), [0.11, 0, 1], [qw/red green blue/], 'convert nice blue to RGB');

$yuv = $space->convert_from( 'RGB', [ 0.8156, 0.0470588, 0.137254]);
is_tuple( $space->round($yuv, 5), [0.28713, -0.08458+0.5, 0.37694+0.5], [qw/Y U V/], 'convert nice red from RGB');

$rgb = $space->convert_to( 'RGB', [0.2871348716, -0.0845829679232+0.5, 0.3769366478976+0.5]);
is_tuple( $space->round($rgb, 5), [0.8156, 0.04706, 0.13725], [qw/red green blue/], 'convert nice red to RGB');

exit 0;
