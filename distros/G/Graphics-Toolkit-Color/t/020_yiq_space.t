#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 51;

my $module = 'Graphics::Toolkit::Color::Space::Instance::YIQ';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'YIQ', 'color space has axis initials as name');
is( $space->name('alias'),                     '', 'color space has no alias name');
is( $space->is_name('YIQ'),                     1, 'recognize space name');
is( $space->is_name(''),                        0, 'space name can not be empty');
is( $space->is_axis_name('YIQ'),                0, 'space name is not axis name');
is( $space->is_axis_name('luminance'),          1, 'luminance is an axis name');
is( $space->is_axis_name('in_phase'),           1, 'in_phase is an axis name');
is( $space->is_axis_name('quadrature'),         1, 'quadrature is an axis name');
is( $space->is_axis_name('y'),                  1, 'y is an axis name');
is( $space->is_axis_name('i'),                  1, 'i is an axis name');
is( $space->is_axis_name('q'),                  1, 'q is an axis name');
is( $space->is_axis_name('inphase'),            0, 'can not miss  lettter of axis name');
is( $space->pos_from_axis_name('q'),            2, 'quadrature is the third axis');
is( $space->axis_count,                         3, 'color space has 3 axis');
is( $space->is_euclidean,                       1, 'YIQ is euclidean');
is( $space->is_cylindrical,                     0, 'YIQ is not cylindrical');
is( $space->shape->has_constraints,             0, 'YIQ is a cube wiht all the edges, no constraints');
is( $space->can_convert('rgb'),                 1, 'do only convert from and to rgb');
is( $space->can_convert('yiq'),                 0, 'can not convert to itself');

is( ref $space->check_value_shape([0, 0, 0]),            'ARRAY',   'check neutral YIQ values are in bounds');
is( ref $space->check_value_shape([0, -0.5959, 0.5227]), 'ARRAY',   'check YIQ values works on lower bound values');
is( ref $space->check_value_shape([1, -0.5227, 0.5227]), 'ARRAY',   'check YIQ values works on upper bound values');
is( ref $space->check_value_shape([0,0]),                     '',   "YIQ got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),              '',   "YIQ got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),              '',   "luminance value is too small");
is( ref $space->check_value_shape([1.1, 0, 0]),               '',   "luminance value is too big");
is( ref $space->check_value_shape([0, -0.6, 0]),              '',   "in_phase value is too small");
is( ref $space->check_value_shape([0, 0.6, 0]),               '',   "in_phase value is too big");
is( ref $space->check_value_shape([0, 0, .6 ] ),              '',   "quadrature value is too small");
is( ref $space->check_value_shape([0, 0, -.6] ),              '',   "quadrature value is too big");

is( $space->is_value_tuple([0,0,0]),                    1, 'value vector has 3 elements');
is( $space->is_partial_hash({i => 1, Quadrature => 0}), 1, 'found hash with some keys');
is( $space->format([0,0,0], 'css_string'), 'yiq(0, 0, 0)', 'can format css string');

my $yiq = $space->deformat(['YIQ', 1, 0, -0.1]);
is_tuple( $yiq, [1, 0, -0.1], [qw/Y I Q/], 'deformat flat named ARRAY');

$yiq = $space->convert_from( 'RGB', [ 0, 0, 0]);
is_tuple( $yiq, [0, 0.5, 0.5], [qw/Y I Q/], 'convert black from RGB');

$yiq = $space->denormalize( [0, 0.5, 0.5] );
is_tuple( $yiq, [0, 0, 0], [qw/Y I Q/], 'denormalize black in YIQ');

$yiq = $space->normalize( [0, 0, 0] );
is_tuple( $yiq, [0, 0.5, 0.5], [qw/Y I Q/], 'normalize black in YIQ');

my $rgb = $space->convert_to( 'RGB', [0, 0.5, 0.5]);
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], 'convert black back to RGB');

$yiq = $space->convert_from( 'RGB', [ 1, 1, 1]);
is_tuple( $yiq, [1, 0.5, 0.5], [qw/Y I Q/], 'convert white from RGB');

$yiq = $space->denormalize( [1, 0.5, 0.5] );
is_tuple( $yiq, [1, 0, 0], [qw/Y I Q/], 'denormalize white in YIQ');

$rgb = $space->convert_to( 'RGB', [1, .5, .5]);
is_tuple( $rgb, [1, 1, 1], [qw/red green blue/], 'convert white back to RGB');

$yiq = $space->convert_from( 'RGB', [ .5, .5, .5]);
is_tuple( $yiq, [.5, 0.5, 0.5], [qw/Y I Q/], 'convert grey from RGB');

$yiq = $space->denormalize( [0.5, 0.5, 0.5] );
is_tuple( $yiq, [.5, 0, 0], [qw/Y I Q/], 'denormalize grey in YIQ');

$yiq = $space->normalize( [0.5, 0, 0] );
is_tuple( $yiq, [0.5, 0.5, 0.5], [qw/Y I Q/], 'normalize grey in YIQ');

$rgb = $space->convert_to( 'RGB', [.5, .5, .5]);
is_tuple( $rgb, [.5, .5, .5], [qw/red green blue/], 'convert grey back to RGB');

$yiq = $space->convert_from( 'RGB', [ 0.11, 0, 1]);
is_tuple( $space->round($yiq, 5), [0.14689, 0.28541, 0.81994], [qw/Y I Q/], 'convert nice blue from RGB');

$yiq = $space->denormalize( [0.14689, 0.2854077865, 0.8199397359] );
is_tuple( $space->round($yiq, 5), [0.14689, -0.25575, 0.33446], [qw/Y I Q/], 'denormalized nice blue in YIQ');

$yiq = $space->normalize( [0.1433137, -0.255751, 0.334465] );
is_tuple( $space->round($yiq, 6), [0.143314, 0.285408, 0.81994], [qw/Y I Q/], 'normalized nice blue in YIQ');

$rgb = $space->convert_to( 'RGB', [0.14689, 0.2854077865,  0.8199397359]);
is_tuple( $space->round($rgb, 5), [0.11, 0, 1], [qw/red green blue/], 'convert nice blue back to RGB');

exit 0;
