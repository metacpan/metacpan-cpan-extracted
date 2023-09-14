#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 53;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::HSV';
use Graphics::Toolkit::Color::Space::Util ':all';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'HSV',                     'color space has right name');
is( $def->dimensions,     3,                     'color space has 3 dimensions');


ok( !$def->check([0,0,0]),       'check hsv values works on lower bound values');
ok( !$def->check([360,100,100]), 'check hsv values works on upper bound values');
warning_like {$def->check([0,0])}        {carped => qr/needs 3 values/}, "check cmy got too few values";
warning_like {$def->check([0, 0, 0, 0])} {carped => qr/needs 3 values/}, "check cmy got too many values";

warning_like {$def->check([-1, 0, 0])}  {carped => qr/hue value/},   "hue value is too small";
warning_like {$def->check([0.5, 0,0])}  {carped => qr/hue value/},   "hue value is not integer";
warning_like {$def->check([361, 0,0])}  {carped => qr/hue value/},   "hue value is too big";
warning_like {$def->check([0, -1, 0])}  {carped => qr/saturation value/}, "saturation value is too small";
warning_like {$def->check([0, 0.5,0])}  {carped => qr/saturation value/}, "saturation value is not integer";
warning_like {$def->check([0, 101,0])}  {carped => qr/saturation value/}, "saturation value is too big";
warning_like {$def->check([0,0, -1 ])}  {carped => qr/value value/},  "value value is too small";
warning_like {$def->check([0,0, 0.5])}  {carped => qr/value value/},  "value value is not integer";
warning_like {$def->check([0,0, 101])}  {carped => qr/value value/},  "value value is too big";

my @hsv = $def->clamp([]);
is( int @hsv,  3,     'clamp added three missing values as zero');
is( $hsv[0],   0,     'default color is black (H)');
is( $hsv[1],   0,     'default color is black (S)');
is( $hsv[2],   0,     'default color is black (V)');
@hsv = $def->clamp([0,100]);
is( int @hsv,  3,     'added one missing value');
is( $hsv[0],   0,     'carried first min value');
is( $hsv[1], 100,     'carried second max value');
is( $hsv[2],   0,     'set missing color value to zero (V)');
@hsv = $def->clamp([-1.1,-1,101,4]);
is( int @hsv,  3,     'removed superfluous value');
is( $hsv[0], 359,     'rotated up (H) value and removed decimals');
is( $hsv[1],   0,     'clamped up too small (S) value');
is( $hsv[2], 100,     'clamped down too large (V) value');;

@hsv = $def->deconvert( [0.5, 0.5, 0.5], 'RGB');
is( int @hsv,  3,     'converted color grey has three hsv values');
is( $hsv[0],   0,     'converted color grey has computed right hue value');
is( $hsv[1],   0,     'converted color grey has computed right saturation');
is( $hsv[2],  0.5,     'converted color grey has computed right value');

my @rgb = $def->convert( [0, 0, 0.5], 'RGB');
is( int @rgb,  3,     'converted back color grey has three rgb values');
is( $rgb[0], 0.5,     'converted back color grey has right red value');
is( $rgb[1], 0.5,     'converted back color grey has right green value');
is( $rgb[2], 0.5,     'converted back color grey has right blue value');

@rgb = $def->convert( [0.972222222, 0.9, 0.78], 'RGB');
is( int @rgb,  3,     'converted red color into tripled');
is( $rgb[0], 0.78,    'right red value');
is( $rgb[1], 0.078,   'right green value');
is( close_enough($rgb[2], 0.196), 1,    'right blue value');

@hsv = $def->deconvert( [0.78, 0.078, 0.196078431], 'RGB');
is( int @hsv,  3,      'converted nice blue has three hsv values');
is( close_enough($hsv[0], 0.97222), 1, 'converted nice blue has computed right hue value');
is( $hsv[1],  .9,      'converted nice blue has computed right saturation');
is( $hsv[2],  .78,     'converted nice blue has computed right value');

@rgb = $def->convert( [0.76666, .83, .24], 'RGB');
is( int @rgb,  3,     'converted red color into tripled');
is( close_enough($rgb[0], 0.156862), 1,   'right red value');
is( close_enough($rgb[1], 0.03921),  1,   'right green value');
is( close_enough($rgb[2], 0.2352),   1,   'right blue value');

@hsv = $def->deconvert( [40/255, 10/255, 60/255], 'RGB');
is( int @hsv,  3,      'converted nice blue has three hsv values');
is( close_enough($hsv[0], 0.766666), 1, 'converted nice blue has computed right hue value');
is( close_enough($hsv[1],  .83),     1, 'converted nice blue has computed right saturation');
is( close_enough($hsv[2],  .24),     1, 'converted nice blue has computed right value');

exit 0;

