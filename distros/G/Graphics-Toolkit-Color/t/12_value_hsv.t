#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 71;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Value::HSV';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');

my $chk_hsv        = \&Graphics::Toolkit::Color::Value::HSV::check;
ok( !$chk_hsv->(0,0,0),       'check hsv values works on lower bound values');
ok( !$chk_hsv->(359,100,100), 'check hsv values works on upper bound values');
warning_like {$chk_hsv->(0,0)}       {carped => qr/exactly 3/},   "check hsv got too few values";
warning_like {$chk_hsv->(0,0,0,0)}   {carped => qr/exactly 3/},   "check hsv got too many  values";
warning_like {$chk_hsv->(-1, 0,0)}   {carped => qr/hue value/},   "hue value is too small";
warning_like {$chk_hsv->(0.5, 0,0)}  {carped => qr/hue value/},   "hue value is not integer";
warning_like {$chk_hsv->(360, 0,0)}  {carped => qr/hue value/},   "hue value is too big";
warning_like {$chk_hsv->(0, -1, 0)}  {carped => qr/saturation value/}, "saturation value is too small";
warning_like {$chk_hsv->(0, 0.5, 0)} {carped => qr/saturation value/}, "saturation value is not integer";
warning_like {$chk_hsv->(0, 101,0)}  {carped => qr/saturation value/}, "saturation value is too big";
warning_like {$chk_hsv->(0,0, -1 )}  {carped => qr/value value/},  "value is too small";
warning_like {$chk_hsv->(0,0, 0.5 )} {carped => qr/value value/},  "value is not integer";
warning_like {$chk_hsv->(0,0, 101)}  {carped => qr/value value/},  "value is too big";

my @hsv = $def->trim();
is( int @hsv,  3,     'default color is set');
is( $hsv[0],   0,     'default color is black (H) no args');
is( $hsv[1],   0,     'default color is black (S) no args');
is( $hsv[2],   0,     'default color is black (L) no args');
@hsv = $def->trim(1,2);
is( int @hsv,  3,     'added missing value');
is( $hsv[0],   1,     'default color is black (H) too few args');
is( $hsv[1],   2,     'default color is black (S) too few args');
is( $hsv[2],   0,     'default color is black (L) too few args');
@hsv = $def->trim(1,2,3,4);
is( int @hsv,  3,     'removed superfluous value');
is( $hsv[0],   1,     'default color is black (H) too many args');
is( $hsv[1],   2,     'default color is black (S) too many args');
is( $hsv[2],   3,     'default color is black (L) too many args');;

@hsv = $def->trim(-1,-1,-1);
is( int @hsv,  3,     'color is trimmed up');
is( $hsv[0], 359,     'too low hue value is rotated up');
is( $hsv[1],   0,     'too low green value is trimmed up');
is( $hsv[2],   0,     'too low blue value is trimmed up');
@hsv = $def->trim(360, 101, 101);
is( int @hsv,  3,     'color is trimmed up');
is( $hsv[0],   0,     'too high hue value is rotated down');
is( $hsv[1], 100,     'too high saturation value is trimmed down');
is( $hsv[2], 100,     'too high lightness value is trimmed down');

@hsv = $def->deconvert( [128, 128, 128], 'RGB');
is( int @hsv,  3,     'converted color grey has three hsl values');
is( $hsv[0],   0,     'converted color grey has computed right hue value');
is( $hsv[1],   0,     'converted color grey has computed right saturation');
is( $hsv[2],  50,     'converted color grey has computed right lightness');

my @rgb = $def->convert( [0, 0, 50], 'RGB');
is( int @rgb,  3,     'converted back color grey has three rgb values');
is( $rgb[0], 128,     'converted back color grey has right red value');
is( $rgb[1], 128,     'converted back color grey has right green value');
is( $rgb[2], 128,     'converted back color grey has right blue value');

@rgb = $def->convert( [360, -10, 50], 'RGB');
is( int @rgb,  3,     'trimmed and converted back color grey');
is( $rgb[0], 128,     'right red value');
is( $rgb[1], 128,     'right green value');
is( $rgb[2], 128,     'right blue value');

@hsv = $def->deconvert( [0, 40, 120], 'RGB');
is( int @hsv,  3,     'converted nice blue has three hsl values');
is( $hsv[0], 220,     'converted nice blue has computed right hue value');
is( $hsv[1], 100,     'converted nice blue has computed right saturation');
is( $hsv[2],  47,     'converted nice blue has computed right value');

@rgb = $def->convert( [220, 100, 47], 'RGB');
is( int @rgb,  3,     'converted back nice blue has three rgb values');
is( $rgb[0],   0,     'converted back nice blue has right red value');
is( $rgb[1],  40,     'converted back nice blue has right green value');
is( $rgb[2], 120,     'converted back nice blue has right blue value');

@hsv = $def->deconvert( [120, 40, 0], 'RGB');
is( int @hsv,  3,     'converted nice red has three hsl values');
is( $hsv[0],  20,     'converted nice red has computed right hue value');
is( $hsv[1], 100,     'converted nice red has computed right saturation');
is( $hsv[2],  47,     'converted nice red has computed right value');

@rgb = $def->convert( [20, 100, 47], 'RGB');
is( int @rgb,  3,     'converted back nice red has three rgb values');
is( $rgb[0], 120,     'converted back nice red has right red value');
is( $rgb[1],  40,     'converted back nice red has right green value');
is( $rgb[2],   0,     'converted back nice red has right blue value');

my @d = $def->delta([2,2,2],[2,2,2]);
is( int @d,   3,      'zero delta vector has right length');
is( $d[0],    0,      'no delta in hue component');
is( $d[1],    0,      'no delta in saturation component');
is( $d[2],    0,      'no delta in lightness component');

@d = $def->delta([10,20,20],[350,22,17]);
is( int @d,   3,      'delta vector has right length');
is( $d[0],  -20,      'computed hue right across the cylindrical border');
is( $d[1],    2,      'correct delta on saturation');
is( $d[2],   -3,      'correct lightness even it was negative');

exit 0;
