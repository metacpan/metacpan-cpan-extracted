#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 76;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Values;

my (@values, $values);
my $fuchsia = Graphics::Toolkit::Color::Values->new_from_tuple([255,0,256], 'RGB');
my $blue_hsl = Graphics::Toolkit::Color::Values->new_from_any_input({hue => 240, s => 100, l => 50});

#### normalized ########################################################
$values = $fuchsia->normalized();
is( ref $values, 'ARRAY',  'get fuchsia value tuple');
is( @$values,          3,  'has 3 values');
is( $values->[0],      1,  'red value is right');
is( $values->[1],      0,  'green value is right');
is( $values->[2],      1,  'blue value is right');
$values = $fuchsia->normalized('RGB');
is( ref $values, 'ARRAY',  'RGB is default color, get same values');
is( @$values,          3,  'same 3 values');
is( $values->[0],      1,  'red value is right');
is( $values->[1],      0,  'green value is right');
is( $values->[2],      1,  'blue value is right');
$values = $fuchsia->normalized('CMYK');
is( ref $values, 'ARRAY',  'get CMYK values');
is( @$values,          4,  'all 4 values');
is( $values->[0],      0,  'cyan value is right');
is( $values->[1],      1,  'magenta value is right');
is( $values->[2],      0,  'yellow value is right');
is( $values->[3],      0,  'key value is right');

#### shaped ##########################################################
$values = $fuchsia->shaped();
is( ref $values, 'ARRAY',  'get fuchsia RGB (default) values in ragular range');
is( @$values,          3,  'all 3 values');
is( $values->[0],    255,  'red value is right');
is( $values->[1],      0,  'green value is right');
is( $values->[2],    255,  'blue value is right');
$values = $fuchsia->shaped('CMYK', [[-10,5],10, [-1,5], 20]);
is( ref $values, 'ARRAY',  'get CMYK values with custom ranges');
is( @$values,          4,  '4 values');
is( $values->[0],    -10,  'cyan value is right');
is( $values->[1],     10,  'magenta value is right');
is( $values->[2],     -1,  'yellow value is right');
is( $values->[3],      0,  'key value is right');
$values = $fuchsia->shaped('XYZ', undef, [0, 1,2]);
is( ref $values, 'ARRAY',  'get XYZ values with custom precision');
is( @$values,          3,  '3 values');
is( $values->[0],     59,  'X value is right');
is( $values->[1],   28.5,  'Y value is right');
is( $values->[2],   96.96, 'Z value is right');

#### formatted #########################################################
#~space, @~|~format, @~|~range, @~|~suffix
is( ref $fuchsia->formatted(), '',  'formatted needs arguments');
is( $fuchsia->formatted(undef, 'named_string'), 'rgb: 255, 0, 255',       'just format name is enough');
is( $fuchsia->formatted('CMY', 'named_string'), 'cmy: 0, 1, 0',           'understand color spaces');
is( $fuchsia->formatted('CMY', 'css_string', '+'), 'cmy(0+, 1+, 0+)',     'and value suffix');
is( $fuchsia->formatted('CMY', 'css_string', '+', [[-2,10]]), 'cmy(-2+, 10+, -2+)','and ranges');
is( $fuchsia->formatted('XYZ', 'css_string', undef, undef, [2,1,0]), 'xyz(59.29, 28.5, 97)','and precision');
is( $blue_hsl->formatted('HSL', 'css_string', '', 1, [2,0,1]), 'hsl(0.67, 1, 0.5)' ,'all arguments at once');
is( ref $fuchsia->formatted('CMY', 'array'),      '',  'array format is RGB only');
is( ref $fuchsia->formatted('CMY', 'hex_string'), '',  'hex_string formatis RGB only');
is( $fuchsia->formatted('RGB', 'hex_string'), '#FF00FF', 'but works under RGB');
$values = $fuchsia->formatted('RGB', 'array');
is( ref $values,  'ARRAY',  'get fuchsia RGB values in array format');
is( @$values,           3,  'all 3 values');
is( $values->[0],     255,  'red value is right');
is( $values->[1],       0,  'green value is right');
is( $values->[2],     255,  'blue value is right');
$values = $fuchsia->formatted( undef, 'named_array');
is( ref $values,  'ARRAY',  'get fuchsia RGB values in named array format');
is( @$values,           4,  'all 4 values');
is( $values->[0],    'RGB', 'first value is space name');
is( $values->[1],     255,  'red value is right');
is( $values->[2],       0,  'green value is right');
is( $values->[3],     255,  'blue value is right');
$values = $fuchsia->formatted( 'CMYK', 'named_array',['','','-','+'], 10);
is( ref $values,  'ARRAY',  'fuchsia CMYK values as named array with custom suffix and special range');
is( @$values,           5,  'all 5 values');
is( $values->[0],  'CMYK', 'first value is space name');
is( $values->[1],       0,  'red value is right');
is( $values->[2],      10,  'magenta value is right');
is( $values->[3],    '0-',  'yellow value is right');
is( $values->[4],    '0+',  'key value is right');
@values = $fuchsia->formatted('RGB', 'list');
is( @values,            3,  'got RGB tuple in list format');
is( $values[0],       255,  'red value is right');
is( $values[1],         0,  'green value is right');
is( $values[2],       255,  'blue value is right');
$values = $fuchsia->formatted( 'CMYK', 'hash');
is( ref $values,    'HASH',  'fuchsia CMYK values as hash');
is( int keys %$values,   4,  'has 4 keys');
is( $values->{'cyan'},   0, 'cyan value is right');
is( $values->{'magenta'},1, 'magenta value is right');
is( $values->{'yellow'}, 0, 'yellow value is right');
is( $values->{'key'},    0, 'key value is right');
$values = $fuchsia->formatted( 'CMYK', 'char_hash');
is( ref $values,    'HASH',  'fuchsia CMYK values as hash with character long keys');
is( int keys %$values,   4,  'has 4 keys');
is( $values->{'c'},      0, 'cyan value is right');
is( $values->{'m'},      1, 'magenta value is right');
is( $values->{'y'},      0, 'yellow value is right');
is( $values->{'k'},      0, 'key value is right');

exit 0;
