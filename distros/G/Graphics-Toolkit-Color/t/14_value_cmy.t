#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 60;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Value::CMY';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');

my $chk_cmy        = \&Graphics::Toolkit::Color::Value::CMY::check;
ok( !$chk_cmy->(0,0,0),       'check cmyk values works on lower bound values');
ok( !$chk_cmy->(1,1,1),       'check cmyk values works on upper bound values');
warning_like {$chk_cmy->(0,0)}       {carped => qr/exactly 3/},   "check cmy got too few values";
warning_like {$chk_cmy->(0,0,0,0)}   {carped => qr/exactly 3/},   "check cmy got too many values";
warning_like {$chk_cmy->(-1, 0,0)}   {carped => qr/cyan value/},   "cyan value is too small";
warning_like {$chk_cmy->(1.1,0,0)}  {carped => qr/cyan value/},   "cyan value is too big";
warning_like {$chk_cmy->(0,-1, 0)}   {carped => qr/magenta value/},  "magenta value is too small";
warning_like {$chk_cmy->(0, 1.1,0)} {carped => qr/magenta value/},  "magenta value is too big";
warning_like {$chk_cmy->(0, 0, -1)} {carped => qr/yellow value/},   "yellow value is too small";
warning_like {$chk_cmy->(0, 0,1.1)} {carped => qr/yellow value/},   "yellow value is too big";


my @cmy = $def->trim();
is( int @cmy,  3,     'default color is set');
is( $cmy[0],   0,     'default color is black (C) no args');
is( $cmy[1],   0,     'default color is black (M) no args');
is( $cmy[2],   0,     'default color is black (Y) no args');

@cmy = $def->trim(0.1, 0.2, 0.3);
is( int @cmy,  3,     'added missing argument in vector');
is( $cmy[0], 0.1,     'passed (C) value when too few args');
is( $cmy[1], 0.2,     'passed (M) value when too few args');
is( $cmy[2], 0.3,     'passed (Y) value when too few args');

@cmy = $def->trim(0.1, 0.2, 0.3, 0.4, 0.5);
is( int @cmy,  3,     'removed missing argument in vector');
is( $cmy[0], 0.1,     'passed (C) value when too few args');
is( $cmy[1], 0.2,     'passed (M) value when too few args');
is( $cmy[2], 0.3,     'passed (Y) value when too few args');

@cmy = $def->trim(-1,-1,-1,-1);
is( int @cmy,  3,     'color is trimmed up but kept vector length');
is( $cmy[0],   0,     'too low cyan value is trimmed up');
is( $cmy[1],   0,     'too low magenta value is trimmed up');
is( $cmy[2],   0,     'too low yellow value is trimmed up');

@cmy = $def->trim(1.1, 2, 101, 10E5);
is( int @cmy,  3,     'color is trimmed down but kept vector length');
is( $cmy[0],   1,     'too high cyan value is rotated down');
is( $cmy[1],   1,     'too high magenta value is trimmed down');
is( $cmy[2],   1,     'too high yellow value is trimmed down');


@cmy = $def->deconvert( [128, 128, 128], 'RGB');
is( int @cmy,   3,     'converted grey has vour cmy values');
is( $cmy[0],  0.5,     'converted grey has right cyan value');
is( $cmy[1],  0.5,     'converted grey has right magenta value');
is( $cmy[2],  0.5,     'converted grey has right yellow value');

my @rgb = $def->convert( [0.5, 0.5, 0.5 ], 'RGB');
is( int @rgb,  3,     'converted back grey has three rgb values');
is( $rgb[0], 128,     'converted back grey has right red value');
is( $rgb[1], 128,     'converted back grey has right green value');
is( $rgb[2], 128,     'converted back grey has right blue value');

@rgb = $def->convert( [-1, -10, 2], 'RGB');
is( int @rgb,   3,     'trimmed and converted back color black');
is( $rgb[0],  255,     'right red value');
is( $rgb[1],  255,     'right green value');
is( $rgb[2],    0,     'right blue value');

@cmy = $def->deconvert( [0, 40, 120], 'RGB');
is( int @cmy,   3,     'converted nice blue has four cmyk values');
is( $cmy[0],   1,     'converted nice blue has computed right C value');
is( close_enough($cmy[1], 0.84375),   1,  'converted nice blue has computed right M value');
is( close_enough($cmy[2], 0.53125),   1,  'converted nice blue has computed right Y value');

@rgb = $def->convert( [1, 0.84375, 0.53125], 'RGB');
is( int @rgb,  3,     'converted back nice blue has three rgb values');
is( $rgb[0],   0,     'converted back nice blue has right red value');
is( $rgb[1],  40,     'converted back nice blue has right green value');
is( $rgb[2], 120,     'converted back nice blue has right blue value');


my @d = $def->delta([.2,.2,.2],[.2,.2,.2]);
is( int @d,   3,      'zero delta vector has right length');
is( $d[0],    0,      'no delta in C component');
is( $d[1],    0,      'no delta in M component');
is( $d[2],    0,      'no delta in Y component');

@d = $def->delta([0.1,0.2,0.4],[0, 0.5, 1]);
is( int @d,   3,      'delta vector has right length');
is( $d[0],  -0.1,     'C delta');
is( $d[1],   0.3,     'M delta');
is( $d[2],   0.6,     'Y delta');


sub close_enough {
    my ($nr, $target) = @_;
    abs($nr - $target) < 0.01
}

exit 0;
