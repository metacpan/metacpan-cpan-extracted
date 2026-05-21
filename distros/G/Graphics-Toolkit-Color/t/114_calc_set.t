#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 93;

my $module = 'Graphics::Toolkit::Color::SetCalculator';
my $value_ref = 'Graphics::Toolkit::Color::Values';
eval "use $module";
is( not($@), 1, "could load the module $module");

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
is_tuple( $values, [330, 100, 50], [qw/hue saturation lightness/], 'first complement is pink');
$values = $colors[1]->shaped('HSL');
is_tuple( $values, [ 60, 100, 50], [qw/hue saturation lightness/], 'second complement is yellow');
$values = $colors[2]->shaped('HSL');
is_tuple( $values, [150, 100, 50], [qw/hue saturation lightness/], 'third complement is teal');
$values = $colors[3]->shaped('HSL');
is_tuple( $values, [240, 100, 50], [qw/hue saturation lightness/], 'forth complement is blue (original color)');

@colors = $complement->($midblue, 5, 0, []);
is( int @colors,                        5,    '4 complements from custom color');
is( $colors[4],                  $midblue,    'got invocant back as last color');
is_tuple( $colors[0]->shaped('HSL'), [ 309, 88, 56], [qw/hue saturation lightness/], 'first complement is lila');
is_tuple( $colors[1]->shaped('HSL'), [  21, 88, 56], [qw/hue saturation lightness/], 'second complement is redish orange');
is_tuple( $colors[2]->shaped('HSL'), [  93, 88, 56], [qw/hue saturation lightness/], 'third complement is green');
	
@colors = $complement->($blue, 3, 2, []);
is( int @colors,                        3,    '3 complements of blue with tilt');
is_tuple( $colors[0]->shaped('HSL'), [ 7, 100, 50], [qw/hue saturation lightness/], 'first complement is red');
is_tuple( $colors[1]->shaped('HSL'), [113, 100, 50], [qw/hue saturation lightness/], 'second complement is green');
is_tuple( $colors[2]->shaped('HSL'), [240, 100, 50], [qw/hue saturation lightness/], 'third complement is blue');

@colors = $complement->($blue, 4, 1.5, [10,-20,30]);
is( int @colors,                        4,    '4 complements of blue with less tilt and moved target');
is_tuple( $colors[0]->shaped('HSL'), [ 36, 84, 75], [qw/hue saturation lightness/], 'first complement is orange');
is_tuple( $colors[1]->shaped('HSL'), [ 70, 80, 80], [qw/hue saturation lightness/], 'second complement is yellow');
is_tuple( $colors[2]->shaped('HSL'), [100, 84, 75], [qw/hue saturation lightness/], 'third complement is green');

#### gradient ##########################################################
# @:colors, +steps, +tilt, :space --> @:values
my $gradient = \&Graphics::Toolkit::Color::SetCalculator::gradient;
@colors = $gradient->([$black, $white], 2, 0, $RGB);
is( int @colors,                       2,  'minimal gradient between black and white');
is_tuple( $colors[0]->normalized(), [ 0, 0, 0], [qw/red green blue/], 'first color has to be black, normalized');
is_tuple( $colors[1]->normalized(), [ 1, 1, 1], [qw/red green blue/], 'first color has to be white, normalized');

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
is_tuple( $colors[1]->shaped(), [ 85, 85, 255], [qw/red green blue/], 'second color is light blue');
is_tuple( $colors[2]->shaped(), [170, 170, 255], [qw/red green blue/], 'third color is lighter blue');

@colors = $gradient->([$red, $white], 3, 0, $HSL);
is( int @colors,                         3,    'got 3 color gradient in HSL');
$values = $colors[0]->shaped('HSL');
is_tuple( $values, [0, 100, 50], [qw/hue saturation lightness/], 'first color in straight gradient between red and white is red');
$values = $colors[1]->shaped('HSL');
is_tuple( $values, [0, 50, 75], [qw/hue saturation lightness/], 'second color is light red');
$values = $colors[2]->shaped('HSL');
is_tuple( $values, [0, 0, 100], [qw/hue saturation lightness/], 'third color is white');

@colors = $gradient->([$red, $white], 3, 1, $HSL);
$values = $colors[1]->shaped('HSL');
is_tuple( $values, [0, 75, 63], [qw/hue saturation lightness/], 'second gradient color between red and white is bright red');

@colors = $gradient->([$red, $white], 3, -1, $HSL);
$values = $colors[1]->shaped('HSL');
is_tuple( $values, [0, 25, 88], [qw/hue saturation lightness/], 'second gradient color between red and white is rose');

@colors = $gradient->([$red, $white, $blue], 9, 0, $RGB);
is( int @colors,                         9,    'got 9 color gradient in RGB');
is( $colors[0]->name,                'red',    'starting with red');
is( $colors[4]->name,              'white',    'white is in the middle');
is( $colors[8]->name,               'blue',    'blue is at the end');
$values = $colors[5]->shaped('RGB');
is_tuple( $values, [191, 191, 255], [qw/red green blue/], 'fifth color in gradient is light blue');

@colors = $gradient->([$red, $white, $blue], 5, 2, $HSL);
$values = $colors[1]->shaped('HSL');
is( int @colors,                         5,    'got 5 colors in complex and tiltet gradient in HSL');
is( $colors[4],                      $blue,    'last color is blue');
$values = $colors[1]->shaped('HSL');
is_tuple( $values, [0, 97, 52], [qw/hue saturation lightness/], 'second gradient color is rose');
$values = $colors[3]->shaped('HSL');
is_tuple( $values, [0, 16, 92], [qw/hue saturation lightness/], 'fourth color is still kind of rose due strong tilt');

#### cluster ###########################################################
# :values, +radius @+|+distance, :space --> @:values
my $cluster = \&Graphics::Toolkit::Color::SetCalculator::cluster;

@colors = $cluster->($midblue, [0,0,0], 1, $RGB);
is( int @colors,                        1,    'computed minimal cuboid cluster with 1 color');
$values = $colors[0]->shaped('RGB');
is_tuple( $values, [43, 52, 242], [qw/red green blue/], 'color nr 1 is the given');

@colors = $cluster->($midblue, [0,1,0], 1, $RGB);
is( int @colors,                        3,    'computed tiny line shaped cluster with 3 colors');
$values = $colors[0]->shaped('RGB');
is_tuple( $values, [43, 51, 242], [qw/red green blue/], 'color nr 1 has less green');
$values = $colors[1]->shaped('RGB');
is_tuple( $values, [43, 52, 242], [qw/red green blue/], 'color nr 2 is the given');
$values = $colors[2]->shaped('RGB');
is_tuple( $values, [43, 53, 242], [qw/red green blue/], 'color nr 3 has more green');

@colors = $cluster->($midblue, [1,1,1], 1, $RGB);
is( int @colors,                       27,    'computed tiny cuboid cluster with 27 colors');
$values = $colors[0]->shaped('RGB');
is_tuple( $values, [42, 51, 241], [qw/red green blue/], 'got first color in min corner');
$values = $colors[26]->shaped('RGB');
is_tuple( $values, [44, 53, 243], [qw/red green blue/], 'got last color in max corner');

@colors = $cluster->($midblue, [1,2,3], 1, $RGB);
is( int @colors,                      105,    'computed cluster with 105 colors');
$values = $colors[0]->shaped('RGB');
is_tuple( $values, [42, 50, 239], [qw/red green blue/], 'got first color in min corner');

@colors = $cluster->($white, [1.01,1.01,1.01], 1, $HSL);
is( int @colors,                       12,    'cluster edging on roof of HSL space');
@colors = $cluster->($midblue, 0, 1, $HSL);
is( int @colors,                        1,    'computed minmal ball shaped cluster with one color');
@colors = $cluster->($midblue, 2.01, 2, $RGB);
is( int @colors,                       13,    'computed smallest ball shaped cluster in RGB');
$values = $colors[0]->shaped('RGB');
is_tuple( $values, [41, 52, 242], [qw/red green blue/], 'values of cluster member nr 1 has more red');
$values = $colors[1]->shaped('RGB');
is_tuple( $values, [43, 52, 242], [qw/red green blue/], 'values of cluster member nr 2');
$values = $colors[2]->shaped('RGB');
is( $values->[0],                      45,    'third color has more red');
$values = $colors[12]->shaped('RGB');
is_tuple( $values, [42, 51, 241], [qw/red green blue/], 'rounded RGB values of cluster member nr 13');

@colors = $cluster->($midblue, 2.01, 2, $HSL);
is( int @colors,                       13,    'same cuboctahedral packing in HSL');
@colors = $cluster->($midblue, 2, 1, $RGB);
is( int @colors,                       47,    'computed smallest ball shaped cluster in RGB');
@colors = $cluster->($white, 1.01, 1, $RGB);
is( int @colors,                        4,    'cluster edging on corner of RGB space');

exit 0;
