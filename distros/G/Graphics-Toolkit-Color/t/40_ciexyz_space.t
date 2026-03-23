#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 72;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';


my $module = 'Graphics::Toolkit::Color::Space::Instance::CIEXYZ';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'XYZ', 'color space name is XYZ');
is( $space->alias,                       'CIEXYZ', 'color space alias name is CIEXYZ');
is( $space->is_name('xyz'),                     1, 'color space name NCol is correct');
is( $space->is_name('CIExyZ'),                  1, 'axis initials do not equal space name this time');
is( $space->is_name('lab'),                     0, 'axis initials do not equal space name this time');
is( $space->axis_count,                         3, 'color space has 3 axis');
is( $space->is_euclidean,                       1, 'CIEXYZ is euclidean');
is( $space->is_cylindrical,                     0, 'CIEXYZ is not cylindrical');

is( ref $space->check_value_shape([0, 0, 0]),          'ARRAY',  'check minimal XYZ values are in bounds');
is( ref $space->check_value_shape([95.0, 100, 108.8]), 'ARRAY',  'check maximal XYZ values');
is( ref $space->check_value_shape([0,0]),                   '',   "XYZ got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),            '',   "XYZ got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),            '',   "X value is too small");
is( ref $space->check_value_shape([96, 0, 0]),              '',   "X value is too big");
is( ref $space->check_value_shape([0, -0.1, 0]),            '',   "Y value is too small");
is( ref $space->check_value_shape([0, 100.1, 0]),           '',   "Y value is too big");
is( ref $space->check_value_shape([0, 0, -.1 ] ),           '',   "Z value is too small");
is( ref $space->check_value_shape([0, 0, 108.9] ),          '',   "Z value is too big");

is( $space->is_value_tuple([0,0,0]),                   1,  'vector has 3 elements');
is( $space->can_convert('rgb'),                        1,  'do only convert from and to rgb');
is( $space->can_convert('RGB'),                        1,  'namespace can be written upper case');
is( $space->is_partial_hash({x => 1, y => 0}),         1,  'found hash with some keys');
is( $space->is_partial_hash({x => 1, z => 0}),         1,  'found hash with some other keys');
is( $space->can_convert('yiq'),                        0,  'can not convert to yiq');

my $val = $space->deformat(['CIEXYZ', 1, 0, -0.1]);
is( int @$val,  3,     'deformated value triplet (vector)');
is( $val->[0], 1,     'first value good');
is( $val->[1], 0,     'second value good');
is( $val->[2], -0.1,  'third value good');
is( $space->format([0,1,0], 'css_string'), 'xyz(0, 1, 0)', 'can format css string');

# black
my $xyz = $space->convert_from( 'RGB', [ 0, 0, 0]);
is( int @$xyz,  3,   'converted black from RGB to XYZ');
is( $xyz->[0],   0,  'right X value');
is( $xyz->[1],   0,  'right Y value');
is( $xyz->[2],   0,  'right Z value');

my $rgb = $space->convert_to( 'RGB', [0, 0, 0]);
is( int @$rgb,                     3,   'convert back from XYZ to RGB');
is( round_decimals($rgb->[0],  5), 0,   'right red value');
is( round_decimals($rgb->[1],  5), 0,   'right green value');
is( round_decimals($rgb->[2],  5), 0,   'right blue value');

# grey
$xyz = $space->convert_from( 'RGB', [ 0.5, 0.5, 0.5]);
is( ref $xyz,                    'ARRAY',  'converted grey from RGB to XYZ');
is( int @$xyz,                         3,  'got three values');
is( round_decimals($xyz->[0],5), 0.21404,  'right X value');
is( round_decimals($xyz->[1],5), 0.21404,  'right Y value');
is( round_decimals($xyz->[2],5), 0.21404,  'right Z value');

$rgb = $space->convert_to( 'RGB', [0.21404, 0.21404, 0.214037]);
is( int @$rgb,                       3,   'converted gray from XYZ to RGB');
is( round_decimals($rgb->[0],5 ),  0.5,   'right red value');
is( round_decimals($rgb->[1],5 ),  0.5,   'right green value');
is( round_decimals($rgb->[2],5 ),  0.5,   'right blue value');

# white
$xyz = $space->convert_from( 'RGB', [1, 1, 1]);
is( int @$xyz,                        3,  'converted white from RGB to XYZ');
is( round_decimals($xyz->[0],   5),   1,  'right X value');
is( round_decimals($xyz->[1],   5),   1,  'right Y value');
is( round_decimals($xyz->[2],   5),   1,  'right Z value');

$rgb = $space->convert_to( 'RGB', [1, 1, 1]);
is( int @$rgb,                        3,  'converted back gray with 3 values');
is( round_decimals($rgb->[0],  5),    1,  'right red value');
is( round_decimals($rgb->[1],  5),    1,  'right green value');
is( round_decimals($rgb->[2],  5),    1,  'right blue value');

# pink
$xyz = $space->convert_from( 'RGB', [1, 0, 0.5]);
is( int @$xyz,                          3,  'converted pink from RGB to XYZ');
is( round_decimals($xyz->[0], 5), 0.47458, 'right X value');
is( round_decimals($xyz->[1], 5), 0.22812, 'right Y value');
is( round_decimals($xyz->[2], 5), 0.20457, 'right Z value');

$rgb = $space->convert_to( 'RGB', [0.474583573181078, 0.228121319314305, 0.204566436987141]);
is( int @$rgb,                      3,   'converted gray from XYZ to RGB');
is( round_decimals($rgb->[0], 5),   1,   'right red value');
is( $rgb->[1] < 0.00005,            1,   'right green value');
is( round_decimals($rgb->[2], 5), 0.5,   'right blue value');

# mid blue
$xyz = $space->convert_from( 'RGB', [.2, .2, .6]);
is( int @$xyz,                           3,  'convert mid blue from RGB to XYZ');
is( round_decimals($xyz->[0],  5), 0.08729,  'right X value');
is( round_decimals($xyz->[1],  5), 0.05371,  'right Y value');
is( round_decimals($xyz->[2],  5), 0.28223,  'right Z value');

$rgb = $space->convert_to( 'RGB', [0.0872931606914908, 0.0537065470652866, 0.282231548430505]);
is( int @$rgb,                      3,   'convert mid blue from XYZ to RGB');
is( round_decimals($rgb->[0], 5), .2  ,   'right red value');
is( round_decimals($rgb->[1], 5), .2  ,   'right green value');
is( round_decimals($rgb->[2], 5), .6  ,   'right blue value');


exit 0;
