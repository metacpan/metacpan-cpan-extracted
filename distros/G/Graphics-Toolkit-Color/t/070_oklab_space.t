#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 53;

# conversion precision could be better
my $module = 'Graphics::Toolkit::Color::Space::Instance::OKLAB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                         'OKLAB', 'color space name is OKLAB');
is( $space->name('alias'),                     '', 'color space has no alias');
is( $space->is_name('lab'),                     0, 'can not shorten the name to "LAB"');
is( $space->is_name('OKlab'),                   1, 'can mix upper and lower case');
is( $space->is_name('xyz'),                     0, 'axis initials do not equal space name this time');
is( $space->is_axis_name('oklab'),              0, 'space name is not axis name');
is( $space->is_axis_name('l'),                  1, '"l" is an axis name');
is( $space->is_axis_name('a'),                  1, '"a" is an axis name');
is( $space->is_axis_name('b'),                  1, '"b" is an axis name');
is( $space->pos_from_axis_name('l'),            0, '"l" is name of first axis');
is( $space->pos_from_axis_name('a'),            1, '"a" is name of second axis');
is( $space->pos_from_axis_name('b'),            2, '"b" is name of third axis');
is( $space->pos_from_axis_name('L*'),       undef, '"L*" is not an axis name');
is( $space->axis_count,                         3, 'OKLAB has 3 axis');
is( $space->is_euclidean,                       1, 'OKLAB is euclidean');
is( $space->is_cylindrical,                     0, 'OKLAB is not cylindrical');

is( ref $space->check_value_shape([0, -0.5, -0.5]),'ARRAY', 'check minimal OKLAB values are in bounds');
is( ref $space->check_value_shape([1, 0.5, 0.5]),  'ARRAY', 'check maximal OKLAB values');
is( ref $space->check_value_shape([0,0]),               '', "OKLAB got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),        '', "OKLAB got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),        '', "L value is too small");
is( ref $space->check_value_shape([1.01, 0, 0]),        '', "L value is too big");
is( ref $space->check_value_shape([0, -.51, 0]),        '', "a value is too small");
is( ref $space->check_value_shape([0,  .51, 0]),        '', "a value is too big");
is( ref $space->check_value_shape([0, 0, -0.51]),       '', "b value is too small");
is( ref $space->check_value_shape([0, 0, 0.52]),        '', "b value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({'L' => 1, 'a' => 0, 'b' => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({l => 1, a => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({a => 1, b => 0}), 1,  'found hash with some other keys');
is( $space->is_partial_hash({a => 1, x => 0}), 0,  'partial hash with bad keys');
is( $space->can_convert('XYZ'),    1,                 'do convert from and to xyz');
is( $space->can_convert('xyz'),    1,              'namespace can be written upper case');
is( $space->can_convert('CIELAB'), 0,              'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'oklab(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['OKLAB', 0, -.1, 0.1]);
is_tuple( $val, [0, -.1, 0.1], [qw/l a b/], 'deformated named ARRAY into tuple');
is( $space->format([0.333, -0.1, 0], 'css_string'), 'oklab(0.333, -0.1, 0)', 'can format css string');

# black
$val = $space->denormalize( [0, .5, .5] );
is_tuple( $val, [0, 0, 0], [qw/l a b/], 'denormalize black');
$val = $space->normalize( [0, 0, 0] );
is_tuple( $val, [0, 0.5, 0.5], [qw/l a b/], 'normalize black');
my $lab = $space->convert_from( 'XYZ', [ 0, 0, 0]);
is_tuple( $space->round( $lab, 9), [0, 0.5, 0.5], [qw/l a b/], 'convert black from XYZ');
my $xyz = $space->convert_to( 'XYZ', [ 0, 0.5, 0.5]);
is_tuple( $space->round( $xyz, 9), [0, 0, 0], [qw/X Y Z/], 'convert black to XYZ');

# white
$val = $space->denormalize( [1, .5, .5] );
is_tuple( $space->round($val, 9), [1, 0, 0], [qw/l a b/], 'denormalize white');
$val = $space->normalize( [1, 0, 0] );
is_tuple( $space->round($val, 9), [1, 0.5, 0.5], [qw/l a b/], 'normalize white');
$lab = $space->convert_from( 'XYZ', [ 1, 1, 1,]);
is_tuple( $space->round( $lab, [5,4,3]), [1, 0.5, 0.5], [qw/l a b/], 'convert white from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 1, 0.5, 0.5]);
is_tuple( $space->round( $xyz, [5,5,3]), [1, 1, 1], [qw/X Y Z/], 'convert white to XYZ');

# nice blue
$lab = $space->convert_from( 'XYZ', [ 0.153608214883163, 0.062, 0.691568013372152]);
is_tuple( $space->round( $lab, 3), [.427, .474,.217], [qw/l a b/], 'convert nice blue from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 0.426796987209832, 0.474256066756847, 0.217395419063849]);
is_tuple( $space->round( $xyz, 3), [0.154, 0.062, 0.692], [qw/X Y Z/], 'convert nice blue to XYZ');

# light blue
$lab = $space->convert_from( 'XYZ', [ 0.589912305, 0.6370801241100728, 0.773381978]);
is_tuple( $space->round( $lab, [5,4,4]), [.85623, .4623, .4687], [qw/l a b/], 'convert light blue from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 0.856232267, 0.462306544, 0.468657634]);
is_tuple( $space->round( $xyz, 5), [0.58991, 0.637080, 0.77338], [qw/X Y Z/], 'convert light blue to XYZ');

# pink
$lab = $space->convert_from( 'XYZ', [ 0.74559151, 0.6327286137205872, 0.596805462 ]);
is_tuple( $space->round( $lab, [5,3,3]), [.86774, .573, .509], [qw/l a b/], 'convert pink from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 0.867737127, 0.572958135, 0.508966821]);
is_tuple( $space->round( $xyz, 5), [0.74559, 0.63273, 0.59680], [qw/X Y Z/], 'convert pink to XYZ');

exit 0;
