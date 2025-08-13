#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 150;
BEGIN { unshift @INC, 'lib', '../lib'}

my $module = 'Graphics::Toolkit::Color::SetCalculator';
my $value_ref = 'Graphics::Toolkit::Color::Values';
use_ok( $module, 'could load the module');

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');
my $XYZ = Graphics::Toolkit::Color::Space::Hub::get_space('XYZ');
my $blue = Graphics::Toolkit::Color::Values->new_from_any_input('blue');
my $red  = Graphics::Toolkit::Color::Values->new_from_any_input('red');
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('black');
my $white = Graphics::Toolkit::Color::Values->new_from_any_input('white');
my $midblue = Graphics::Toolkit::Color::Values->new_from_any_input([43, 52, 242]);
my (@colors, $values);

#### complement ########################################################
# :base_color +steps +tilt %target_delta --> @:values
my $complement = \&Graphics::Toolkit::Color::SetCalculator::complement;
@colors = $complement->($blue, 1, 0, []);
is( int    @colors,                     1,   'got only one complement');
is( ref $colors[0],            $value_ref,   'but it is a value object');
is( $colors[0]->name,            'yellow',   'and has right values');

@colors = $complement->($blue, 2, 0, []);
is( int @colors,                        2,   'got 2 colors, complement and invocant');
is( ref $colors[0],            $value_ref,   'first is a value object');
is( ref $colors[1],            $value_ref,   'second is a value object');
is( $colors[0]->name,            'yellow',   'and has right values');
is( $colors[1],                     $blue,   'got invocant back as second color');

@colors = $complement->($blue, 3, 0, []);
is( int @colors,                        3,   'got 3 "triadic "colors');
is( ref $colors[0],            $value_ref,   'first is a value object');
is( ref $colors[1],            $value_ref,   'second is a value object');
is( ref $colors[2],            $value_ref,   'third is a value object');
is( $colors[0]->name,               'red',   'first color is red');
is( $colors[1]->name,              'lime',   'second color is full green (lime)');
is( $colors[2],                     $blue,   'got invocant back as third color');

@colors = $complement->($blue, 4, 0, []);
is( int @colors,                        4,   'got 4 "tetradic "colors');
is( $colors[0]->name,                  '',   'first color has no name');
is( $colors[1]->name,            'yellow',   'second color is yellow');
is( $colors[2]->name,                  '',   'third color has no name');
is( $colors[3],                     $blue,   'got invocant back as last color');
$values = $colors[0]->shaped('HSL');
is( ref $values,                   'ARRAY',   'RGB values of color 2');
is( int @$values,                        3,   'are 3 values');
is( $values->[0],                      330,   'hue is 90');
is( $values->[1],                      100,   'saturation is 100');
is( $values->[2],                       50,   'lightness is half');
$values = $colors[1]->shaped('HSL');
is( $values->[0],                       60,   'hue of second color is 60');
$values = $colors[2]->shaped('HSL');
is( $values->[0],                      150,   'hue of third color is 150');
$values = $colors[3]->shaped('HSL');
is( $values->[0],                      240,   'hue of fourth color is 240');

@colors = $complement->($midblue, 5, 0, []);
is( int @colors,                        5,    '4 complements from custom color');
is( $colors[4],                  $midblue,    'got invocant back as last color');
$values = $colors[0]->shaped('HSL');
is( ref $colors[0],            $value_ref,    'first color is a value object');
is( $values->[0],                      309,   'hue value from first color is 309');
is( $values->[1],                       88,   'saturation is 88');
is( $values->[2],                       56,   'lightness is 56 as start');
$values = $colors[1]->shaped('HSL');
is( $values->[0],                       21,   'hue value from second color is 21');
is( $values->[1],                       88,   'saturation is 88');
$values = $colors[2]->shaped('HSL');
is( $values->[0],                       93,  'hue value from third color is 93');
is( $values->[2],                       56,   'lightness is 56');

@colors = $complement->($blue, 3, 2, []);
is( int @colors,                        3,    '3 complements with tilt');
$values = $colors[0]->shaped('HSL');
is( $values->[0],                        7,   'hue is 7 = 240 + ((1-(2/3**3)) * 180)');
is( $values->[1],                      100,   'full saturation');
is( $values->[2],                       50,   'half lightness');
$values = $colors[1]->shaped('HSL');
is( $values->[0],                      113,   'hue of second color is 113');

@colors = $complement->($blue, 4, 1.5, [10,-20,30]);
is( int @colors,                        4,    '4 complements with tilt and moved target');
$values = $colors[0]->shaped('HSL');
is( $values->[0],                       36,   'hue of first color is 36 = 240 + 0,823*190');
is( $values->[1],                       84,   'saturation of first color is 84');
is( $values->[2],                       75,   'lightness of first color is ');
$values = $colors[1]->shaped('HSL');
is( $values->[0],                       70,   'hue of target is right');
is( $values->[1],                       80,   'saturation of target is right');
is( $values->[2],                       80,   'lightness of target is right');
$values = $colors[2]->shaped('HSL');
is( $values->[0],                      100,   'hue of third color is 100');
is( $values->[1],                       84,   'saturation of third color is 84');
is( $values->[2],                       75,   'lightness of third color is 75');

#### gradient ##########################################################
# @:colors, +steps, +tilt, :space --> @:values
my $gradient = \&Graphics::Toolkit::Color::SetCalculator::gradient;
@colors = $gradient->([$black, $white], 2, 0, $RGB);
is( int @colors,                       2,  'gradient has length of two');
is( $colors[0]->name,            'black',  'first one is black');
is( $colors[1]->name,            'white',  'second one is white');

@colors = $gradient->([$black, $white], 3, 0, $RGB);
is( int @colors,                        3,  'gradient has length of three');
is( ref $colors[0],           $value_ref,   'first color is a value obj');
is( ref $colors[1],           $value_ref,   'second color is a value obj');
is( ref $colors[2],           $value_ref,   'third color is value obj');
is( $colors[0]->name,             'black',  'first one is black');
is( $colors[1]->name,              'gray',  'second one is grey');
is( $colors[2]->name,             'white',  'third one is white');

@colors = $gradient->([$blue, $white], 4, 0, $RGB);
is( int @colors,                       4,   '4 colors from blue to white');
is( ref $colors[0],           $value_ref,   'first color is a value obj');
is( ref $colors[1],           $value_ref,   'second color is a value obj');
is( ref $colors[2],           $value_ref,   'third color is value obj');
is( ref $colors[3],           $value_ref,   'fourth color is a value obj');
is( $colors[0]->name,             'blue',   'number 1 is blue');
is( $colors[3]->name,            'white',   'number 4 is white');

$values = $colors[1]->shaped();
is( ref $values,                   'ARRAY',   'RGB values of color 2');
is( int @$values,                        3,   'are 3 values');
is( $values->[0],                       85,   'red value is right');
is( $values->[1],                       85,   'green value is right');
is( $values->[2],                      255,   'blue value is right');
$values = $colors[2]->shaped();
is( $values->[0],                      170,   'red value of third color is right');

@colors = $gradient->([$red, $white], 3, 0, $HSL);
is( int @colors,                         3,    'got 3 color gradient in HSL');
$values = $colors[0]->shaped('HSL');
is( $values->[0],                        0,    'hue of red is zero');
is( $values->[1],                      100,    'full saturation of red in HSL');
is( $values->[2],                       50,    'half lightness of red in HSL');
$values = $colors[1]->shaped('HSL');
is( $values->[0],                        0,    'hue of rose is zero');
is( $values->[1],                       50,    'full saturation of red in HSL');
is( $values->[2],                       75,    '3/4 lightness of red in HSL');
$values = $colors[2]->shaped('HSL');
is( $values->[0],                        0,    'hue of white is zero');
is( $values->[1],                        0,    'no saturation of white in HSL');
is( $values->[2],                      100,    'full lightness of white in HSL');

@colors = $gradient->([$red, $white], 3, 1, $HSL);
$values = $colors[1]->shaped('HSL');
is( $values->[0],                        0,    'hue of rose is zero');
is( $values->[1],                       75,    'due tilt middle color saturation is 3/4 red');
is( $values->[2],                       63,    'due tilt middle color lightness is 3/4 red');
@colors = $gradient->([$red, $white], 3, -1, $HSL);
$values = $colors[1]->shaped('HSL');
is( $values->[0],                        0,    'hue of rose is zero');
is( $values->[1],                       25,    'due reverse tilt middle color saturation is 1/4 red');
is( $values->[2],                       88,    'due reverse tilt middle color lightness is 1/4 red');

@colors = $gradient->([$red, $white, $blue], 9, 0, $RGB);
is( int @colors,                         9,    'got 9 color gradient in RGB');
is( $colors[0]->name,                'red',    'starting with red');
is( $colors[4]->name,              'white',    'white is in the middle');
is( $colors[8]->name,               'blue',    'blue is at the end');
$values = $colors[5]->shaped('RGB');
is( ref $values,                  'ARRAY',      'get RGB values inside multi segment gradient');
is( $values->[0],                     191,      'red value is right');
is( $values->[1],                     191,      'green value is right');
is( $values->[2],                     255,      'blue value is right');

@colors = $gradient->([$red, $white, $blue], 5, 2, $HSL);
$values = $colors[1]->shaped('HSL');
is( int @colors,                         5,    'got 5 colors in complex and tiltet gradient in HSL');
is( $colors[4],                      $blue,    'last color is blue');
$values = $colors[1]->shaped('HSL');
is( $values->[0],                        0,    'hue of rose is zero');
is( $values->[1],                       97,    'saturation is 97 = (1-0.03125)*100');
is( $values->[2],                       52,    'lightness is 52 = (1-0.03125)*50)+(0.03125*100)');
$values = $colors[3]->shaped('HSL');
is( $values->[0],                        0,    'fourth color is still rose due strong tilt');
is( $values->[1],                       16,    'saturation is 16 = (1 - ((3/4)**3)) * 100');
is( $values->[2],                       92,    'lightness is 71 = ((1-((3/4)**3)) * 50) + ((3/4)**3 * 100)');


#### cluster ###########################################################
# :values, +radius @+|+distance, :space --> @:values
my $cluster = \&Graphics::Toolkit::Color::SetCalculator::cluster;

@colors = $cluster->($midblue, [0,0,0], 1, $RGB);
is( int @colors,                        1,    'computed minimal cuboid cluster with 1 color');
$values = $colors[0]->shaped('RGB');
is( ref $values,                  'ARRAY',    'got the mid blue values');
is( $values->[0],                      43,    'red value is right');
is( $values->[1],                      52,    'green value is right');
is( $values->[2],                     242,    'blue value is right');

@colors = $cluster->($midblue, [0,1,0], 1, $RGB);
is( int @colors,                        3,    'computed tiny line shaped cluster with 3 colors');
$values = $colors[0]->shaped('RGB');
is( $values->[0],                      43,    'red value of first color is right');
is( $values->[1],                      51,    'green value of first color is right');
$values = $colors[1]->shaped('RGB');
is( $values->[1],                      52,    'green value of second color is right');
is( $values->[2],                     242,    'blue value of second color is right');
is( $colors[2]->shaped('RGB')->[1],    53,    'green value of third color is right');


@colors = $cluster->($midblue, [1,1,1], 1, $RGB);
is( int @colors,                       27,    'computed tiny cuboid cluster with 27 colors');
$values = $colors[0]->shaped('RGB');
is( ref $values,                  'ARRAY',    'got first color in min corner');
is( $values->[0],                      42,    'red value is right');
is( $values->[1],                      51,    'green value is right');
is( $values->[2],                     241,    'blue value is right');
$values = $colors[26]->shaped('RGB');
is( ref $values,                  'ARRAY',    'got last color in max corner');
is( $values->[0],                      44,    'red value is right');
is( $values->[1],                      53,    'green value is right');
is( $values->[2],                     243,    'blue value is right');

@colors = $cluster->($midblue, [1,2,3], 1, $RGB);
is( int @colors,                      105,    'computed cluster with 105 colors');
$values = $colors[0]->shaped('RGB');
is( ref $values,                  'ARRAY',    'got first color in min corner');
is( $values->[0],                      42,    'red value is right');
is( $values->[1],                      50,    'green value is right');
is( $values->[2],                     239,    'blue value is right');

@colors = $cluster->($white, [1,1,1], 1, $HSL);
is( int @colors,                       12,    'cluster edging on roof of HSL space');

@colors = $cluster->($midblue, 0, 1, $HSL);
is( int @colors,                        1,    'computed minmal ball shaped cluster with one color');
@colors = $cluster->($midblue, 2, 2, $RGB);
is( int @colors,                       13,    'computed smallest ball shaped cluster in RGB');
$values = $colors[1]->shaped('RGB');
is( ref $values,                  'ARRAY',    'center color is on pos one');
is( $values->[0],                      43,    'red value is right');
is( $values->[1],                      52,    'green value is right');
is( $values->[2],                     242,    'blue value is right');
$values = $colors[0]->shaped('RGB');
is( $values->[0],                      41,    'first color has less red');
is( $values->[2],                     242,    'blue is same as center');
$values = $colors[2]->shaped('RGB');
is( $values->[0],                      45,    'third color has more red');
$values = $colors[12]->shaped('RGB');
is( $values->[0],                      42,    'red value is right (was rounded up to same)');
is( $values->[1],                      51,    'green value is right');
is( $values->[2],                     241,    'blue value is right (1.4 less but rounded up)');
@colors = $cluster->($midblue, 2, 2, $HSL);
is( int @colors,                       13,    'same cuboctahedral packing in HSL');

@colors = $cluster->($midblue, 2, 1, $RGB);
is( int @colors,                       47,    'computed smallest ball shaped cluster in RGB');

@colors = $cluster->($white, 1, 1, $RGB);
is( int @colors,                        4,    'cluster edging on corner of RGB space');

exit 0;
