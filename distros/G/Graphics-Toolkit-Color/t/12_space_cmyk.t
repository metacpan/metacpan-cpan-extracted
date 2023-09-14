#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 65;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::CMYK';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'CMYK',                     'color space has right name');
is( $def->dimensions,      4,                     'color space has 4 dimensions');

ok( !$def->check([0,0,0,0]),       'check cmy values works on lower bound values');
ok( !$def->check([1, 1, 1,1]),     'check cmy values works on upper bound values');
warning_like {$def->check([0,0,0])}        {carped => qr/needs 4 values/}, "check cmyk got too few values";
warning_like {$def->check([0,0,0,0,0])}  {carped => qr/needs 4 values/}, "check cmyk got too many values";
warning_like {$def->check([-1,0,0,0])}   {carped => qr/cyan value/},   "cyan value is too small";
warning_like {$def->check([2,0,0,0])}    {carped => qr/cyan value/},   "cyan value is too big";
warning_like {$def->check([0,-1,0,0])}   {carped => qr/magenta value/}, "magenta value is too small";
warning_like {$def->check([0,2,0,0])}    {carped => qr/magenta value/}, "magenta value is too big";
warning_like {$def->check([0,0,-1,0])}   {carped => qr/yellow value/},  "yellow value is too small";
warning_like {$def->check([0,0,2,0])}    {carped => qr/yellow value/},  "yellow value is too big";
warning_like {$def->check([0,0,0,-1])}   {carped => qr/key value/},  "key value is too small";
warning_like {$def->check([0,0,0,2])}    {carped => qr/key value/},  "key value is too big";


my @cmyk = $def->clamp([]);
is( int @cmyk,  4,     'missing args are clamped down to black (default color)');
is( $cmyk[0],   0,     'default color is black (C)');
is( $cmyk[1],   0,     'default color is black (M)');
is( $cmyk[2],   0,     'default color is black (Y)');
is( $cmyk[3],   0,     'default color is black (K)');

@cmyk = $def->clamp([0.1, 0.2, 0.3]);
is( int @cmyk,  4,     'clamp added missing argument in vector');
is( $cmyk[0], 0.1,     'passed (C) value when too few args');
is( $cmyk[1], 0.2,     'passed (M) value when too few args');
is( $cmyk[2], 0.3,     'passed (Y) value when too few args');
is( $cmyk[3],   0,     'added zero value (K) when too few args');

@cmyk = $def->clamp([0.1, 0.2, 0.3, 0.4, 0.5]);
is( int @cmyk,  4,     'clamp removed missing argument in vector');
is( $cmyk[0], 0.1,     'passed (C) value when too few args');
is( $cmyk[1], 0.2,     'passed (M) value when too few args');
is( $cmyk[2], 0.3,     'passed (Y) value when too few args');
is( $cmyk[3], 0.4,     'added (K) value when too few args');

@cmyk = $def->clamp([-1,0,1,1.1]);
is( int @cmyk,  4,     'clamp kept vector length');
is( $cmyk[0],   0,     'too low cyan value is clamped up');
is( $cmyk[1],   0,     'min magenta value is kept');
is( $cmyk[2],   1,     'max yellow value is kept');
is( $cmyk[3],   1,     'too large key value is clamped down');


@cmyk = $def->deconvert( [0.5, 0.5, 0.5], 'RGB');
is( int @cmyk,  4,     'converted grey has four cmyk values');
is( $cmyk[0],   0,     'converted grey has right cyan value');
is( $cmyk[1],   0,     'converted grey has right magenta value');
is( $cmyk[2],   0,     'converted grey has right yellow value');
is( $cmyk[3],   0.5,   'converted grey has right key value');

my @rgb = $def->convert( [0, 0, 0, 0.5], 'RGB');
is( int @rgb,  3,     'converted back grey has three rgb values');
is( $rgb[0], 0.5,     'converted back grey has right red value');
is( $rgb[1], 0.5,     'converted back grey has right green value');
is( $rgb[2], 0.5,     'converted back grey has right blue value');

@cmyk = $def->deconvert( [0.3, 0.4, 0.5], 'RGB');
is( int @cmyk,  4,     'converted color has four cmyk values');
is( $cmyk[0],   0.4,     'converted color has right cyan value');
is( $cmyk[1],   0.2,   'converted color has right magenta value');
is( $cmyk[2],   0 ,   'converted color has right yellow value');
is( $cmyk[3],   0.5,   'converted color has right key value');

@rgb = $def->convert( [0.4, 0.2, 0, 0.5], 'RGB');
is( int @rgb,  3,     'trimmed and converted back color black');
is( $rgb[0],   0.3,   'right red value');
is( $rgb[1],   0.4,   'right green value');
is( $rgb[2],   0.5,   'right blue value');

@cmyk = $def->deformat([cmyk => 11, 22, 256, -1]);
is( int @cmyk,  4,     'deformat lc named ARRAY: got 4 values');
is( $cmyk[0],  11,    'cyan got transported');
is( $cmyk[1],  22,    'also too large magenta');
is( $cmyk[2], 256,    'yallow transported, range ignored');
is( $cmyk[3], -1,     'too small key ignored');

@cmyk = $def->deformat(['CMYK', 11, 22, 33]);
is( $cmyk[0],  undef,  'OO deformat reacts only to right amount of values');

@cmyk = $def->deformat('cmyk: -1, 256, 3.3, 4 ');
is( int @cmyk,  4,     'deformat STRING: got 4 values');
is( $cmyk[0],  -1,     'cyan');
is( $cmyk[1], 256,     'magenta');
is( $cmyk[2], 3.3,     'yellow');
is( $cmyk[3],   4,     'key value');

exit 0;
