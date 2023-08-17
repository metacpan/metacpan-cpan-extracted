#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 71;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Value::CMYK';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');

my $chk_cmyk        = \&Graphics::Toolkit::Color::Value::CMYK::check;
ok( !$chk_cmyk->(0,0,0,0),       'check cmyk values works on lower bound values');
ok( !$chk_cmyk->(1,1,1,1), 'check cmyk values works on upper bound values');
warning_like {$chk_cmyk->(0,0,0)}       {carped => qr/exactly 4/},   "check cmyk got too few values";
warning_like {$chk_cmyk->(0,0,0,0,0)}   {carped => qr/exactly 4/},   "check cmyk got too many values";
warning_like {$chk_cmyk->(-1, 0,0,0)}   {carped => qr/cyan value/},   "cyan value is too small";
warning_like {$chk_cmyk->(1.1, 0,0,0)}  {carped => qr/cyan value/},   "cyan value is too big";
warning_like {$chk_cmyk->(0,-1, 0,0)}   {carped => qr/magenta value/},  "magenta value is too small";
warning_like {$chk_cmyk->(0, 1.1, 0,0)} {carped => qr/magenta value/},  "magenta value is too big";
warning_like {$chk_cmyk->(0, 0, -1, 0)} {carped => qr/yellow value/},   "yellow value is too small";
warning_like {$chk_cmyk->(0, 0,1.1, 0)} {carped => qr/yellow value/},   "yellow value is too big";
warning_like {$chk_cmyk->(0,0, 0, -1 )} {carped => qr/key value/},      "key value is too small";
warning_like {$chk_cmyk->(0,0, 0, 1.1)} {carped => qr/key value/},      "key value is too big";


my @cmyk = $def->trim();
is( int @cmyk,  4,     'default color is set');
is( $cmyk[0],   0,     'default color is black (C) no args');
is( $cmyk[1],   0,     'default color is black (M) no args');
is( $cmyk[2],   0,     'default color is black (Y) no args');
is( $cmyk[3],   0,     'default color is black (K) no args');

@cmyk = $def->trim(0.1, 0.2, 0.3);
is( int @cmyk,  4,     'added missing argument in vector');
is( $cmyk[0], 0.1,     'passed (C) value when too few args');
is( $cmyk[1], 0.2,     'passed (M) value when too few args');
is( $cmyk[2], 0.3,     'passed (Y) value when too few args');
is( $cmyk[3],   0,     'added zero value (K) when too few args');

@cmyk = $def->trim(0.1, 0.2, 0.3, 0.4, 0.5);
is( int @cmyk,  4,     'removed missing argument in vector');
is( $cmyk[0], 0.1,     'passed (C) value when too few args');
is( $cmyk[1], 0.2,     'passed (M) value when too few args');
is( $cmyk[2], 0.3,     'passed (Y) value when too few args');
is( $cmyk[3], 0.4,     'added (K) value when too few args');

@cmyk = $def->trim(-1,-1,-1,-1);
is( int @cmyk,  4,     'color is trimmed up but kept vector length');
is( $cmyk[0],   0,     'too low cyan value is trimmed up');
is( $cmyk[1],   0,     'too low magenta value is trimmed up');
is( $cmyk[2],   0,     'too low yellow value is trimmed up');
is( $cmyk[3],   0,     'too low key value is trimmed up');

@cmyk = $def->trim(1.1, 2, 101, 10E5);
is( int @cmyk,  4,     'color is trimmed down but kept vector length');
is( $cmyk[0],   1,     'too high cyan value is rotated down');
is( $cmyk[1],   1,     'too high magenta value is trimmed down');
is( $cmyk[2],   1,     'too high yellow value is trimmed down');
is( $cmyk[3],   1,     'too high key value is trimmed down');



@cmyk = $def->deconvert( [128, 128, 128], 'RGB');
is( int @cmyk,  4,     'converted grey has vour cmyk values');
is( $cmyk[0],   0,     'converted grey has right cyan value');
is( $cmyk[1],   0,     'converted grey has right magenta value');
is( $cmyk[2],   0,     'converted grey has right yellow value');
is( close_enough($cmyk[3], 0.5), 1, 'converted grey has right key value');

my @rgb = $def->convert( [0, 0, 0, 0.5], 'RGB');
is( int @rgb,  3,     'converted back grey has three rgb values');
is( $rgb[0], 128,     'converted back grey has right red value');
is( $rgb[1], 128,     'converted back grey has right green value');
is( $rgb[2], 128,     'converted back grey has right blue value');

@rgb = $def->convert( [-1, -10, -1, 2], 'RGB');
is( int @rgb,  3,     'trimmed and converted back color black');
is( $rgb[0],   0,     'right red value');
is( $rgb[1],   0,     'right green value');
is( $rgb[2],   0,     'right blue value');

@cmyk = $def->deconvert( [0, 40, 120], 'RGB');
is( int @cmyk,  4,     'converted nice blue has four cmyk values');
is( $cmyk[0],   1,     'converted nice blue has computed right C value');
is( close_enough($cmyk[1], 0.66),   1,  'converted nice blue has computed right M');
is( $cmyk[2],   0,     'converted nice blue has computed right Y');
is( close_enough($cmyk[3], 0.53),   1,  'converted nice blue has computed right key value'); # 46

@rgb = $def->convert( [1, 0.6666, 0, 0.53], 'RGB');
is( int @rgb,  3,     'converted back nice blue has three rgb values');
is( $rgb[0],   0,     'converted back nice blue has right red value');
is( $rgb[1],  40,     'converted back nice blue has right green value');
is( $rgb[2], 120,     'converted back nice blue has right blue value');


my @d = $def->delta([.2,.2,.2,.2],[.2,.2,.2,.2]);
is( int @d,   4,      'zero delta vector has right length');
is( $d[0],    0,      'no delta in C component');
is( $d[1],    0,      'no delta in M component');
is( $d[2],    0,      'no delta in Y component');
is( $d[3],    0,      'no delta in K component');

@d = $def->delta([0.1,0.2,0.3,0.4],[0, 0.3, 0.5, 1]);
is( int @d,   4,      'delta vector has right length');
is( $d[0],  -0.1,     'C delta');
is( $d[1],   0.1,     'M delta');
is( $d[2],   0.2,     'Y delta');
is( $d[3],   0.6,     'K delta');


sub close_enough {
    my ($nr, $target) = @_;
    abs($nr - $target) < 0.01
}

exit 0;
