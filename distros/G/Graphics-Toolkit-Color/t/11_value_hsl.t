#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 63;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Value::HSL';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');

my $chk_hsl        = \&Graphics::Toolkit::Color::Value::HSL::check;

ok( !$chk_hsl->(0,0,0),       'check hsl values works on lower bound values');
ok( !$chk_hsl->(359,100,100), 'check hsl values works on upper bound values');
warning_like {$chk_hsl->(0,0)}       {carped => qr/exactly 3/},   "check hsl got too few values";
warning_like {$chk_hsl->(0,0,0,0)}   {carped => qr/exactly 3/},   "check hsl got too many  values";
warning_like {$chk_hsl->(-1, 0,0)}   {carped => qr/hue value/},   "hue value is too small";
warning_like {$chk_hsl->(0.5, 0,0)}  {carped => qr/hue value/},   "hue value is not integer";
warning_like {$chk_hsl->(360, 0,0)}  {carped => qr/hue value/},   "hue value is too big";
warning_like {$chk_hsl->(0, -1, 0)}  {carped => qr/saturation value/}, "saturation value is too small";
warning_like {$chk_hsl->(0, 0.5, 0)} {carped => qr/saturation value/}, "saturation value is not integer";
warning_like {$chk_hsl->(0, 101,0)}  {carped => qr/saturation value/}, "saturation value is too big";
warning_like {$chk_hsl->(0,0, -1 )}  {carped => qr/lightness value/},  "lightness value is too small";
warning_like {$chk_hsl->(0,0, 0.5 )} {carped => qr/lightness value/},  "lightness value is not integer";
warning_like {$chk_hsl->(0,0, 101)}  {carped => qr/lightness value/},  "lightness value is too big";


my @hsl = $def->trim();
is( int @hsl,  3,     'default color is set');
is( $hsl[0],   0,     'default color is black (H) no args');
is( $hsl[1],   0,     'default color is black (S) no args');
is( $hsl[2],   0,     'default color is black (L) no args');

@hsl = $def->trim(1,2);
is( int @hsl,  3,     'added missing value');
is( $hsl[0],   1,     'default color is black (H) too few args');
is( $hsl[1],   2,     'default color is black (S) too few args');
is( $hsl[2],   0,     'default color is black (L) too few args');

@hsl = $def->trim(1,2,3,4);
is( int @hsl,  3,     'removed superfluous value');
is( $hsl[0],   1,     'default color is black (H) too many args');
is( $hsl[1],   2,     'default color is black (S) too many args');
is( $hsl[2],   3,     'default color is black (L) too many args');;

@hsl = $def->trim(-1,-1,-1);
is( int @hsl,  3,     'color is trimmed up');
is( $hsl[0], 359,     'too low hue value is rotated up');
is( $hsl[1],   0,     'too low green value is trimmed up');
is( $hsl[2],   0,     'too low blue value is trimmed up');

@hsl = $def->trim(360, 101, 101);
is( int @hsl,  3,     'color is trimmed up');
is( $hsl[0],   0,     'too high hue value is rotated down');
is( $hsl[1], 100,     'too high saturation value is trimmed down');
is( $hsl[2], 100,     'too high lightness value is trimmed down');


@hsl = $def->deconvert( [127, 127, 127], 'RGB');
is( int @hsl,  3,     'converted color grey has three hsl values');
is( $hsl[0],   0,     'converted color grey has computed right hue value');
is( $hsl[1],   0,     'converted color grey has computed right saturation');
is( $hsl[2],  50,     'converted color grey has computed right lightness');

my @rgb = $def->convert( [0, 0, 50], 'RGB');
is( int @rgb,  3,     'converted back color grey has three rgb values');
is( $rgb[0], 127,     'converted back color grey has right red value');
is( $rgb[1], 127,     'converted back color grey has right green value');
is( $rgb[2], 127,     'converted back color grey has right blue value');

@rgb = $def->convert( [360, -10, 50], 'RGB');
is( int @rgb,  3,     'trimmed and converted back color grey');
is( $rgb[0], 127,     'right red value');
is( $rgb[1], 127,     'right green value');
is( $rgb[2], 127,     'right blue value');

@hsl = $def->deconvert( [0, 40, 120], 'RGB');
is( int @hsl,  3,     'converted nice blue has three hsl values');
is( $hsl[0], 220,     'converted nice blue has computed right hue value');
is( $hsl[1], 100,     'converted nice blue has computed right saturation');
is( $hsl[2],  23,     'converted nice blue has computed right lightness'); # is 23.5 - rounding error

@rgb = $def->convert( [220, 100, 24], 'RGB');
is( int @rgb,  3,     'converted back nice blue has three rgb values');
is( $rgb[0],   0,     'converted back nice blue has right red value');
is( $rgb[1],  40,     'converted back nice blue has right green value');
is( $rgb[2], 122,     'converted back nice blue has right blue value');

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
