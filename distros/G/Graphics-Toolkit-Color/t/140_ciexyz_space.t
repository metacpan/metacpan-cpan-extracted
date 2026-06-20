#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 49;

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIEXYZ';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'XYZ', 'color space name is XYZ');
is( $space->name('alias'),               'CIEXYZ', 'color space alias name is CIEXYZ');
is( $space->is_name('xyz'),                     1, 'color space name in lower case');
is( $space->is_name('X.Y.Z.'),                  1, 'color space name with dots (period)');
is( $space->is_name('CIExyZ'),                  1, 'alias is accepted name');
is( $space->is_name('lab'),                     0, 'axis initials do not equal space name this time');
is( $space->is_axis_name('X'),                  1, '"X" is an axis name');
is( $space->is_axis_name('Y'),                  1, '"Y" is an axis name');
is( $space->is_axis_name('Z'),                  1, '"Z" is an axis name');
is( $space->is_axis_name('A'),                  0, 'bad axis name');
is( $space->pos_from_axis_name('X'),            0, '"X" is name of first axis');
is( $space->pos_from_axis_name('Y'),            1, '"Y" is name of second axis');
is( $space->pos_from_axis_name('Z'),            2, '"Z" is name of third axis');
is( $space->pos_from_axis_name('a'),        undef, '"a" is not an axis name');
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

is( $space->is_value_tuple([0,0,0]),                   1,  'tuple has 3 elements');
is( $space->is_number_tuple([0,0,0]),                  1,  'tuple has 3 numbers');
is( $space->can_convert('linearrgb'),                  1,  'do only convert from and to rgb');
is( $space->can_convert('Linear_RGB'),                 1,  'namespace can be written upper case');
is( $space->can_convert('RGB'),                        0,  'does not convert directly to SRGB');
is( $space->is_partial_hash({x => 1, y => 0}),         1,  'found hash with some keys');
is( $space->is_partial_hash({x => 1, z => 0}),         1,  'found hash with some other keys');
is( $space->can_convert('yiq'),                        0,  'can not convert to yiq');

my $xyz = $space->deformat(['CIEXYZ', 1, 0, -0.1]);
is_tuple( $xyz, [1, 0, -0.1], [qw/X Y Z/], 'deformat named ARRAY');
is( $space->format([0,1,0], 'css_string'), 'xyz(0, 1, 0)', 'can format css string');

# black
$xyz = $space->convert_from( 'LinearRGB', [ 0, 0, 0]);
is_tuple( $xyz, [0, 0, 0], [qw/X Y Z/], 'convert black from linear RGB');
my $rgb = $space->convert_to( 'LinearRGB', [0, 0, 0]);
is_tuple( $space->round($rgb, 5), [0, 0, 0], [qw/red green blue/], 'convert black back to linear RGB');

# grey
$xyz = $space->convert_from( 'LinearRGB', [ 0.5, 0.5, 0.5]);
is_tuple( $space->round($xyz, 6), [47.5235, 50.000005, 54.4415], [qw/X Y Z/], 'convert grey from linear RGB');
$rgb = $space->convert_to( 'LinearRGB', [47.5235, 50.000005, 54.4415]);
is_tuple( $space->round($rgb, 6), [0.5, 0.5, 0.5], [qw/red green blue/], 'convert grey back to linear RGB');

# white
$xyz = $space->convert_from( 'LinearRGB', [1, 1, 1]);
is_tuple( $space->round($xyz, 4), [95.047, 100, 108.883], [qw/X Y Z/], 'convert white from linear RGB');
$rgb = $space->convert_to( 'LinearRGB', [95.047, 100, 108.883]);
is_tuple( $space->round($rgb, 6), [1, 1, 1], [qw/red green blue/], 'convert white back to linear RGB');

# pink
$xyz = $space->convert_from( 'LinearRGB', [1, 0, 0.5]);
is_tuple( $space->round($xyz, 7), [50.2675181, 24.8760383, 49.4485935], [qw/X Y Z/], 'convert pink from linear RGB');
$rgb = $space->convert_to( 'LinearRGB', [50.2675181, 24.8760383, 49.4485935]);
is_tuple( $space->round($rgb, 6), [1, 0, .5], [qw/red green blue/], 'convert pink back to linear RGB');

# mid blue
$xyz = $space->convert_from( 'LinearRGB', [.2, .2, .6]);
is_tuple( $space->round($xyz, 7), [26.2268993, 22.8870045, 59.7887631], [qw/X Y Z/], 'convert mid blue from linear RGB');
$rgb = $space->convert_to( 'LinearRGB', [26.2268993, 22.8870045, 59.7887631]);
is_tuple( $space->round($rgb, 6), [ .2, .2, .6], [qw/red green blue/], 'convert mid blue back to linear RGB');

exit 0;
