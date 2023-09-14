#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 82;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::RGB';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got right return value by loading module');
is( $def->name,       'RGB',                     'color space has right name');
is( $def->dimensions,     3,                     'color space has 3 dimensions');


ok( !$def->check([0,0,0]),       'check rgb values works on lower bound values');
ok( !$def->check([255,255,255]), 'check rgb values works on upper bound values');
warning_like {$def->check([0,0])}        {carped => qr/needs 3 values/}, "check rgb got too few values";
warning_like {$def->check([0, 0, 0, 0])} {carped => qr/needs 3 values/}, "check rgb got too many values";
warning_like {$def->check([-1, 0, 0])}   {carped => qr/red value/},   "red value is too small";
warning_like {$def->check([0.5, 0, 0])}  {carped => qr/red value/},   "red value is not integer";
warning_like {$def->check([256, 0, 0])}  {carped => qr/red value/},   "red value is too big";
warning_like {$def->check([0, -1, 0])}   {carped => qr/green value/}, "green value is too small";
warning_like {$def->check([0, 0.5, 0])}  {carped => qr/green value/}, "green value is not integer";
warning_like {$def->check([0, 256, 0])}  {carped => qr/green value/}, "green value is too big";
warning_like {$def->check([0, 0, -1 ] )} {carped => qr/blue value/},  "blue value is too small";
warning_like {$def->check([0, 0, 0.5] )} {carped => qr/blue value/},  "blue value is not integer";
warning_like {$def->check([0, 0, 256] )} {carped => qr/blue value/},  "blue value is too big";

my @rgb = $def->clamp([]);
is( int @rgb,  3,     'clamp resets missing color to black');
is( $rgb[0],   0,     'default color is black (R)');
is( $rgb[1],   0,     'default color is black (G)');
is( $rgb[2],   0,     'default color is black (B)');

@rgb = $def->clamp([1,2]);
is( $rgb[0],   1,     'carry over first arg');
is( $rgb[1],   2,     'carry over second arg');
is( $rgb[2],   0,     'set missing color value to zero');
@rgb = $def->clamp([1.1, 2, 3, 4]);
is( $rgb[0],   1,     'clamped none int value down');
is( $rgb[1],   2,     'carried color is black (G) took second of too many args');
is( $rgb[2],   3,     'default color is black (B) too third of too many args');
is( int @rgb,  3,     'left out the needless argument');
@rgb = $def->clamp([-1,10,256]);
is( int @rgb,  3,     'clamp does not change number of negative values');
is( $rgb[0],   0,     'too low red value is clamp up');
is( $rgb[1],  10,     'in range green value is not touched');
is( $rgb[2], 255,     'too large blue value is clamp down');

is(    $def->format([0,0,0],      'hex'), '#000000',     'converted black from rgb to hex');
is( uc $def->format([255,255,255],'HEX'), '#FFFFFF',     'converted white from rgb to hex');
is( uc $def->format([ 10, 20, 30],'hex'), '#0A141E',     'converted random color from rgb to hex');

@rgb = $def->deformat('#332200');
is( int @rgb,  3,     'could deformat hex string');
is( $rgb[0],  51,     'red is correctly tranlated from hex');
is( $rgb[1],  34,     'green is correctly tranlated from hex');
is( $rgb[2],   0,     'blue is correctly tranlated from hex');

@rgb = $def->deformat('#DEF');
is( int @rgb,  3,     'could deformat short hex string');
is( $rgb[0], 221,     'converted (short form) hex to RGB red is correct');
is( $rgb[1], 238,     'converted (short form) hex to RGB green is correct');
is( $rgb[2], 255,     'converted (short form) hex to RGB blue is correct');

@rgb = $def->deformat([ 33, 44, 55]);
is( int @rgb,  3,     'number triplet in ARRAY is recognized by ARRAY');
is( $rgb[0],  33,     'red is transported');
is( $rgb[1],  44,     'green is transported');
is( $rgb[2],  55,     'blue is transported');

@rgb = $def->deformat([rgb => 11, 22, 256]);
is( int @rgb,  3,     'deformat lc named ARRAY: got 3 values');
is( $rgb[0],  11,     'red is correct');
is( $rgb[1],  22,     'green got transported');
is( $rgb[2], 256,     'blue value does not get clamped');

@rgb = $def->deformat(['CMY', 11, 22, 33]);
is( $rgb[0],  undef,  'OO deformat reacts only to right name');

@rgb = $def->deformat('RGB: -1, 256, 3.3 ');
is( int @rgb,  3,     'deformat STRING format: got 3 values');
is( $rgb[0],  -1,     'to small red is not clamped up');
is( $rgb[1], 256,     'too large green is not clamped down');
is( $rgb[2], 3.3,     'blue decimals do not get clamped');


@rgb = $def->deformat('rgb:0,1,2');
is( int @rgb,  3,     'deformat STRING format without spaces and lc name: got 3 values');
is( $rgb[0],   0,     'red is zero');
is( $rgb[1],   1,     'green is one');
is( $rgb[2],   2,     'blue is two');

@rgb = $def->deformat('cmy: 1,2,3.3');
is( $rgb[0],  undef,  'OO deformat STRING reacts only to right space name');

is( $def->format([0,256,3.3], 'string'), 'rgb: 0, 256, 3.3', 'formated rgb triplet into value string');

@rgb = $def->deformat('rgb( -1 , 2.3, 4444)');
is( int @rgb,  3,     'deformat css STRING formatwith all hurdles: got 3 values');
is( $rgb[0],   -1,    'red is -1');
is( $rgb[1],   2.3,   'green is one');
is( $rgb[2],   4444,  'blue is two');

is( $def->format([-1,2.3,4444], 'css_string'), 'rgb(-1,2.3,4444)', 'formated rgb triplet into css string');

my $rgb = $def->format([0,256,3.3], 'array');
is( ref $rgb,  'ARRAY',  'formated into ARRAY');
is( @$rgb,           4,  'named RGB tuple has 4 elements');
is( $rgb->[0],  'rgb',  'tuple color name space');
is( $rgb->[1],   0,     'red in minimal');
is( $rgb->[2],   256,   'green is too large');
is( $rgb->[3],   3.3,   'blue still has decimal');

is( $def->format([10,20,30], 'hex'), '#0a141e', 'formated rgb triplet into hex string');

my @d = $def->delta([0,44,256],[256,88,0]);
is( int @d,   3,      'delta vector has right length');
is( $d[0],  256,      'delta in R component');
is( $d[1],   44,      'delta in G component');
is( $d[2], -256,      'delta in B component');

@rgb = $def->denormalize( [0.3, 0.4, 0.5], [[0,255],[0,255],[0,255]] );
is( int @rgb,  3,     'denormalized triplet');
is( $rgb[0],   77,    'right red value');
is( $rgb[1],   102,   'right green value');
is( $rgb[2],   128,   'right blue value');


exit 0;
