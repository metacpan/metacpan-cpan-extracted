#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 62;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

my $module = 'Graphics::Toolkit::Color::Space::Instance::HWB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                             'HWB', 'color space has axis initials as name');
is( $space->alias,                               '', 'color space has no alias name');
is( $space->is_name('HwB'),                       1, 'recognized name');
is( $space->is_name('Hsl'),                       0, 'ignored wrong name');
is( $space->axis_count,                           3, 'color space has 3 axis');
is( ref $space->check_value_shape([0, 0, 0]),     'ARRAY', 'check HWB values works on lower bound values');
is( ref $space->check_value_shape([360,100,100]), 'ARRAY', 'check HWB values works on upper bound values');
is( ref $space->check_value_shape([0,0]),              '', "HWB got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '', "HWB got too many values");
is( ref $space->check_value_shape([-1, 0, 0]),         '', "hue value is too small");
is( ref $space->check_value_shape([1.1, 0, 0]),        '', "hue is not integer");
is( ref $space->check_value_shape([361, 0, 0]),        '', "hue value is too big");
is( ref $space->check_value_shape([0, -1, 0]),         '', "whiteness value is too small");
is( ref $space->check_value_shape([0, 1.1, 0]),        '', "whiteness value is not integer");
is( ref $space->check_value_shape([0, 101, 0]),        '', "whiteness value is too big");
is( ref $space->check_value_shape([0, 0, -1 ] ),       '', "blackness value is too small");
is( ref $space->check_value_shape([0, 0, 1.1] ),       '', "blackness value is not integer");
is( ref $space->check_value_shape([0, 0, 101] ),       '', "blackness value is too big");

my $val = $space->round([1,22.5, 11.111111]);
is( ref $val,                'ARRAY', 'rounded value tuple int tuple');
is( int @$val,                     3, 'right amount of values');
is( $val->[0],                     1, 'first value kept');
is( $val->[1],                    23, 'second value rounded up');
is( $val->[2],                    11, 'third value rounded down');

my $rgb = $space->convert_to( 'RGB', [0.83333, 0, 1]); # should become black despite color value
is( int @$rgb,  3,     'converted black');
is( $rgb->[0],   0,     'right red value');
is( $rgb->[1],   0,     'right green value');
is( $rgb->[2],   0,     'right blue value');


my $hwb = $space->convert_from( 'RGB', [ .5, .5, .5]);
is( int @$hwb,   3,     'converted color grey has three hwb values');
is( $hwb->[0],   0,     'converted color grey has computed right hue value');
is( $hwb->[1],  .5,     'converted color grey has computed right whiteness');
is( $hwb->[2],  .5,     'converted color grey has computed right blackness');

$rgb = $space->convert_to( 'RGB', [0, 0.5, .5]);
is( int @$rgb,     3,   'converted back color grey has three rgb values');
is( $rgb->[0],   0.5,   'converted back color grey has right red value');
is( $rgb->[1],   0.5,   'converted back color grey has right green value');
is( $rgb->[2],   0.5,   'converted back color grey has right blue value');

$hwb = $space->convert_from( 'RGB', [210/255, 20/255, 70/255]);
is( int @$hwb,                          3,  'convert nice magenta from RGB to HWB');
is( round_decimals( $hwb->[0],5), 0.95614,  'right hue value');
is( round_decimals( $hwb->[1],5), 0.07843,  'right whiteness');
is( round_decimals( $hwb->[2],5), 0.17647,  'right blackness');

$rgb = $space->convert_to( 'RGB', [0.956140350877193, 0.0784313725490196, 0.176470588235294]);
is( int @$rgb,  3,     'converted back nice magenta');
is( round_decimals( $rgb->[0], 5), 0.82353,   'right red value');
is( round_decimals( $rgb->[1], 5), 0.07843,   'right green value');
is( round_decimals( $rgb->[2], 5), round_decimals(70/255, 5),  'right blue value');


$val = $space->form->remove_suffix([qw/360 100% 100%/]);
is( ref $val,                'ARRAY', 'value tuple without suffixes is a tuple');
is( int @$val,                     3, 'right amount of values');
is( $val->[0],                   360, 'first value is right');
is( $val->[1],                   100, 'second value right');
is( $val->[2],                   100, 'third value right');

$val = $space->deformat('hwb(240, 88%, 22%)');
is( ref $val,                'ARRAY', 'deformated CSS string into value tuple');
is( int @$val,                     3, 'right amount of values');
is( $val->[0],                   240, 'first value is right');
is( $val->[1],                    88, 'second value right');
is( $val->[2],                    22, 'third value right');

$val = $space->deformat('hwb(240, 88, 22)');
is( ref $val,                'ARRAY', 'deformated CSS string without suffix into value tuple');
is( int @$val,                     3, 'right amount of values');
is( $val->[0],                   240, 'first value is right');
is( $val->[1],                    88, 'second value right');
is( $val->[2],                    22, 'third value right');

is( $space->format([240, 88, 22], 'css_string'),  'hwb(240, 88%, 22%)', 'converted tuple into css string');
is( $space->format([240, 88, 22], 'css_string', ''),  'hwb(240, 88, 22)', 'converted tuple into css string without suffixes');

exit 0;
