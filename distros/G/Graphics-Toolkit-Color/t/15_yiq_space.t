#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 90;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::YIQ';

my $space = eval "require $module";
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'YIQ', 'color space has axis initials as name');
is( $space->alias,                             '', 'color space has no alias name');
is( $space->axis_count,                         3, 'color space has 3 axis');
is( $space->is_euclidean,                       1, 'YIQ is euclidean');
is( $space->is_cylindrical,                     0, 'YIQ is not cylindrical');


is( ref $space->check_value_shape([0, 0, 0]),              'ARRAY',   'check neutral YIQ values are in bounds');
is( ref $space->check_value_shape([0, -0.5959, 0.5227]),   'ARRAY',   'check YIQ values works on lower bound values');
is( ref $space->check_value_shape([1, -0.5227, 0.5227]),   'ARRAY',   'check YIQ values works on upper bound values');
is( ref $space->check_value_shape([0,0]),              '',   "YIQ got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "YIQ got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "luminance value is too small");
is( ref $space->check_value_shape([1.1, 0, 0]),        '',   "luminance value is too big");
is( ref $space->check_value_shape([0, -0.6, 0]),       '',   "in_phase value is too small");
is( ref $space->check_value_shape([0, 0.6, 0]),        '',   "in_phase value is too big");
is( ref $space->check_value_shape([0, 0, .6 ] ),       '',   "quadrature value is too small");
is( ref $space->check_value_shape([0, 0, -.6] ),       '',   "quadrature value is too big");


is( $space->is_value_tuple([0,0,0]),           1,   'value vector has 3 elements');
is( $space->is_partial_hash({i => 1, Quadrature => 0}), 1, 'found hash with some keys');
is( $space->can_convert('rgb'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('yiq'), 0,                 'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'yiq(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['YIQ', 1, 0, -0.1]);
is( int @$val,    3,  'deformated value triplet (vector)');
is( $val->[0],    1,  'first value good');
is( $val->[1],    0,  'second value good');
is( $val->[2], -0.1,  'third value good');


my $yiq = $space->convert_from( 'RGB', [ 0, 0, 0]);
is( ref $yiq, 'ARRAY','reconverted black has to be a ARRAY reference');
is( int @$yiq,  3,    'reconverted black has three YIQ values');
is( $yiq->[0],  0,    'reconverted black has computed right luminance value');
is( $yiq->[1],  0.5,  'reconverted black has computed right in-phase');
is( $yiq->[2],  0.5,  'reconverted black has computed right quadrature');

$yiq = $space->denormalize( [0, 0.5, 0.5] );
is( ref $yiq, 'ARRAY','denormalized black has to be a ARRAY reference');
is( int @$yiq,  3,    'denormalized black has three YIQ values');
is( $yiq->[0],  0,    'denormalized black has computed right luminance value');
is( $yiq->[1],  0,    'denormalized black has computed right in-phase');
is( $yiq->[2],  0,    'denormalized black has computed right quadrature');

$yiq = $space->normalize( [0, 0, 0] );
is( ref $yiq, 'ARRAY','normalized black has to be a ARRAY reference');
is( int @$yiq,  3,    'normalized black has three YIQ values');
is( $yiq->[0],  0,    'normalized black has computed right luminance value');
is( $yiq->[1],  0.5,  'normalized black has computed right in-phase');
is( $yiq->[2],  0.5,  'normalized black has computed right quadrature');

my $rgb = $space->convert_to( 'RGB', [0, 0.5, 0.5]);
is( int @$rgb,  3,    'converted black has three rgb values');
is( $rgb->[0],  0,    'converted black has right red value');
is( $rgb->[1],  0,    'converted black has right green value');
is( $rgb->[2],  0,    'converted black has right blue value');


$yiq = $space->convert_from( 'RGB', [ 1, 1, 1]);
is( int @$yiq,                    3, 'reconvert white from RGB to YIQ');
is( round_decimals($yiq->[0],4),  1, 'white has right luminance value');
is( round_decimals($yiq->[1],4), .5, 'white has right in-phase');
is( round_decimals($yiq->[2],4), .5, 'white has right quadrature');

$yiq = $space->denormalize( [1, 0.5, 0.5] );
is( int @$yiq,  3,    'denormalized white has three YIQ values');
is( $yiq->[0],  1,    'denormalized white has computed right luminance value');
is( $yiq->[1],  0,    'denormalized white has computed right in-phase');
is( $yiq->[2],  0,    'denormalized white has computed right quadrature');

$rgb = $space->convert_to( 'RGB', [1, .5, .5]);
is( int @$rgb,  3,    'converted white has three rgb values');
is( $rgb->[0],  1,    'converted white has right red value');
is( $rgb->[1],  1,    'converted white has right green value');
is( $rgb->[2],  1,    'converted white has right blue value');


$yiq = $space->convert_from( 'RGB', [ .5, .5, .5]);
is( int @$yiq,                     3, 'converted gray from RGB to YIQ');
is( round_decimals($yiq->[0], 4), .5, 'gray has right luminance value');
is( round_decimals($yiq->[1], 4), .5, 'gray has right in-phase');
is( round_decimals($yiq->[2], 4), .5, 'gray has right quadrature');

$yiq = $space->denormalize( [0.5, 0.5, 0.5] );
is( int @$yiq,  3,    'denormalized gray has three YIQ values');
is( $yiq->[0],  0.5,  'denormalized gray has computed right luminance value');
is( $yiq->[1],  0,    'denormalized gray has computed right in-phase');
is( $yiq->[2],  0,    'denormalized gray has computed right quadrature');

$yiq = $space->normalize( [0.5, 0, 0] );
is( int @$yiq,  3,    'normalized gray has three YIQ values');
is( $yiq->[0],  0.5,  'normalized gray has computed right luminance value');
is( $yiq->[1],  0.5,  'normalized gray has computed right in-phase');
is( $yiq->[2],  0.5,  'normalized gray has computed right quadrature');

$rgb = $space->convert_to( 'RGB', [.5, .5, .5]);
is( int @$rgb,  3,    'converted white has three rgb values');
is( $rgb->[0], .5,    'converted white has right red value');
is( $rgb->[1], .5,    'converted white has right green value');
is( $rgb->[2], .5,    'converted white has right blue value');


$yiq = $space->convert_from( 'RGB', [ 0.11, 0, 1]);
is( int @$yiq,  3,                'converted nice blue from RGB to YIQ');
is( round_decimals( $yiq->[0], 5), 0.14689,   'reconverted nice blue has right luminance');
is( round_decimals( $yiq->[1], 5), 0.28541,   'reconverted nice blue has right in-phase');
is( round_decimals( $yiq->[2], 5), 0.81994,   'reconverted nice blue has right quadrature');

$yiq = $space->denormalize( [0.14689, 0.2854077865, 0.8199397359] );
is( int @$yiq,  3,    'denormalized gray has three YIQ values');
is( round_decimals( $yiq->[0], 5), 0.14689,   'denormalized nice blue has right luminance value');
is( round_decimals( $yiq->[1], 5),-0.25575,   'denormalized nice blue has right in-phase');
is( round_decimals( $yiq->[2], 5), 0.33446,   'denormalized nice blue has right quadrature');


$yiq = $space->normalize( [0.1433137, -0.255751, 0.334465] );
is( int @$yiq,  3,    'normalized nice blue has three YIQ values');
is( round_decimals( $yiq->[0], 6),  0.143314,  'normalized nice blue has right luminance value');
is( round_decimals( $yiq->[1], 6),  0.285408,  'normalized nice blue has right in-phase');
is( round_decimals( $yiq->[2], 6),  0.81994,   'normalized nice blue has right quadrature');

$rgb = $space->convert_to( 'RGB', [0.14689, 0.2854077865,  0.8199397359]);
is( int @$rgb,  3,    'converted nice blue color, has three rgb values');
is( round_decimals( $rgb->[0], 5), .11,   'converted nice blue color, has right red value');
is( round_decimals( $rgb->[1], 5),  0,    'converted nice blue color, has right green value');
is( round_decimals( $rgb->[2], 5),  1,    'converted nice blue color, has right blue value');

exit 0;


