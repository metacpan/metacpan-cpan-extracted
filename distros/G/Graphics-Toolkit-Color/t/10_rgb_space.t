#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 95;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::RGB';

my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got right return value by loading module');
is( $space->name,       'RGB',                     'color space has right name');
is( $space->is_name('rgb'), 1,                     'asked for right space name');
is( $space->alias,         '',                     'color space has no alias name');
is( $space->axis_count,     3,                     'color space has 3 axis');

is( ref $space->check_value_shape( [0,0,0]),       'ARRAY', 'check RGB values works on lower bound values');
is( ref $space->check_value_shape( [255,255,255]), 'ARRAY', 'check RGB values works on upper bound values');
is( ref $space->check_value_shape( [0,0]),              '', "RGB got too few values");
is( ref $space->check_value_shape( [0, 0, 0, 0]),       '', "RGB got too many values");
is( ref $space->check_value_shape( [-1, 0, 0]),         '', "red value is too small");
is( ref $space->check_value_shape( [0.5, 0, 0]),        '', "red value is not integer");
is( ref $space->check_value_shape( [256, 0, 0]),        '', "red value is too big");
is( ref $space->check_value_shape( [0, -1, 0]),         '', "green value is too small");
is( ref $space->check_value_shape( [0, 0.5, 0]),        '', "green value is not integer");
is( ref $space->check_value_shape( [0, 256, 0]),        '', "green value is too big");
is( ref $space->check_value_shape( [0, 0, -1 ] ),       '', "blue value is too small");
is( ref $space->check_value_shape( [0, 0, 0.5] ),       '', "blue value is not integer");
is( ref $space->check_value_shape( [0, 0, 256] ),       '', "blue value is too big");


my $rgb = $space->clamp([]);
is( int @$rgb,  3,     'clamp resets missing color to black');
is( $rgb->[0],   0,     'default color is black (R)');
is( $rgb->[1],   0,     'default color is black (G)');
is( $rgb->[2],   0,     'default color is black (B)');

$rgb = $space->clamp([1,2]);
is( $rgb->[0],   1,     'carry over first arg');
is( $rgb->[1],   2,     'carry over second arg');
is( $rgb->[2],   0,     'set missing color value to zero');

$rgb = $space->clamp([1.1, 2, 3, 4]);
is( int @$rgb,   3,     'left out the needless argument');
is( $rgb->[0],  1.1,    'not clamped badly rounded value (job of round)');
is( $rgb->[1],   2,     'carried color is black (G) took second of too many args');
is( $rgb->[2],   3,     'default color is black (B) too third of too many args');

$rgb = $space->clamp([-1,10,256]);
is( int @$rgb,   3,     'clamp does not change number of negative values');
is( $rgb->[0],   0,     'too low red value is clamp up');
is( $rgb->[1],  10,     'in range green value is not touched');
is( $rgb->[2], 255,     'too large blue value is clamp down');

is(    $space->format([0,0,0],      'hex_string'), '#000000',     'converted black from rgb to hex');
is( uc $space->format([255,255,255],'HEX_string'), '#FFFFFF',     'converted white from rgb to hex');
is( uc $space->format([ 10, 20, 30],'hex_strinG'), '#0A141E',     'converted random color from rgb to hex');

my ($vals, $name) = $space->deformat('#332200');
is( ref $vals,  'ARRAY', 'could deformat hex string');
is( $name,  'hex_string', 'could deformat hex string');
is( @$vals,       3,      'right amount of values');
is( $vals->[0],  51,      'red is correctly tranlated from hex');
is( $vals->[1],  34,      'green is correctly tranlated from hex');
is( $vals->[2],   0,      'blue is correctly tranlated from hex');

($rgb, $name) = $space->deformat('#DEF');
is( ref $rgb,    'ARRAY', 'could deformat short hex string');
is( int @$rgb,    3,      'right amount of values');
is( $name,  'hex_string', 'could deformat hex string');
is( $rgb->[0],   221,     'converted (short form) hex to RGB red is correct');
is( $rgb->[1],   238,     'converted (short form) hex to RGB green is correct');
is( $rgb->[2],   255,     'converted (short form) hex to RGB blue is correct');

($rgb, $name) = $space->deformat([ 33, 44, 55]);
is( $name,     'array', 'could deformat ARRAY ref (RGB special)');
is( ref $rgb,  'ARRAY', 'got value tuple');
is( int @$rgb,   3,     'number triplet in ARRAY is recognized by ARRAY');
is( $rgb->[0],  33,     'red is transported');
is( $rgb->[1],  44,     'green is transported');
is( $rgb->[2],  55,     'blue is transported');

($rgb, $name) = $space->deformat([rgb => 11, 22, 256]);
is( $name,     'named_array', 'could deformat named array');
is( ref $rgb,  'ARRAY', 'deformat lc named ARRAY');
is( int @$rgb,  3,      'got 3 values');
is( $rgb->[0],  11,     'red is correct');
is( $rgb->[1],  22,     'green got transported');
is( $rgb->[2], 256,     'blue value does not get clamped');

$rgb = $space->deformat(['CMY', 11, 22, 33]);
is( $rgb->[0],  undef,  'OO deformat reacts only to right name');

($rgb, $name) = $space->deformat('RGB: -1, 256, 3.3 ');
is( $name,  'named_string', 'could deformat named string');
is( int @$rgb,   3,     'deformat STRING format: got 3 values');
is( $rgb->[0],  -1,     'to small red is not clamped up');
is( $rgb->[1], 256,     'too large green is not clamped down');
is( $rgb->[2], 3.3,     'blue decimals do not get clamped');


($rgb, $name) = $space->deformat('rgb:0,1,2');
is( $name,  'named_string', 'could deformat named string without spaces');
is( int @$rgb,  3,     'deformat STRING format without spaces and lc name: got 3 values');
is( $rgb->[0],   0,    'red is zero');
is( $rgb->[1],   1,    'green is one');
is( $rgb->[2],   2,    'blue is two');

$rgb = $space->deformat('cmy: 1,2,3.3');
is( $rgb->[0],  undef,  'OO deformat STRING reacts only to right space name');
is( $space->format([0,256,3.3], 'named_string'), 'rgb: 0, 256, 3.3', 'formated rgb triplet into value string');


($rgb, $name) = $space->deformat('rgb( -1 , 2.3, 4444)');
is( $name,    'css_string', 'could deformat css string');
is( int @$rgb,     3,   'got 3 values');
is( $rgb->[0],    -1,   'red is -1');
is( $rgb->[1],   2.3,   'green is one');
is( $rgb->[2],   4444,  'blue is two');

is( $space->format([-1,2.3,4444], 'css_string'), 'rgb(-1, 2.3, 4444)', 'formated rgb triplet into css string');

$rgb = $space->format([0,256,3.3], 'named_array');
is( ref $rgb,  'ARRAY',  'formated into named ARRAY');
is( @$rgb,           4,  'named RGB tuple has 4 elements');
is( $rgb->[0],   'RGB',  'tuple color name space');
is( $rgb->[1],    0,     'red in minimal');
is( $rgb->[2],    256,   'green is too large');
is( $rgb->[3],    3.3,   'blue still has decimal');

is( $space->format([10,20,30], 'hex_string'), '#0A141E', 'formated rgb triplet into hex string');

my $d = $space->delta([0,44,256],[256,88,0]);
is( int @$d,    3,      'delta vector has right length');
is( $d->[0],  256,      'delta in R component');
is( $d->[1],   44,      'delta in G component');
is( $d->[2], -256,      'delta in B component');

$rgb = $space->denormalize( [0.3, 0.4, 0.5], 255, 0 );
is( int @$rgb,    3,     'denormalized triplet, got 3 values');
is( $rgb->[0], 76.5,    'right red value');
is( $rgb->[1],   102,   'right green value');
is( $rgb->[2], 127.5,   'right blue value');
exit 0;

exit 0;
