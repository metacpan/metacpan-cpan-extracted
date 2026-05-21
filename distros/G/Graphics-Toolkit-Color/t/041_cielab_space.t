#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 62;

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELAB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'LAB', 'color space name is LAB');
is( $space->name('alias'),               'CIELAB', 'color space alias name is CIELAB');
is( $space->is_name('lab'),                     1, 'color space name "lab" is correct');
is( $space->is_name('CIElab'),                  1, 'axis initials do not equal space name this time');
is( $space->is_name('xyz'),                     0, 'axis initials do not equal space name this time');
is( $space->is_axis_name('lab'),                0, 'space name is not axis name');
is( $space->is_axis_name('L*'),                 1, '"L*" is an axis name');
is( $space->is_axis_name('a*'),                 1, '"a*" is an axis name');
is( $space->is_axis_name('b*'),                 1, '"b*" is an axis name');
is( $space->is_axis_name('*'),                  0, 'can not miss a lettter of axis name');
is( $space->is_axis_name('l'),                  1, '"l" is an axis name');
is( $space->is_axis_name('a'),                  1, '"a" is an axis name');
is( $space->is_axis_name('b'),                  1, '"b" is an axis name');
is( $space->pos_from_axis_name('L*'),           0, '"L*" is name of first axis');
is( $space->pos_from_axis_name('a*'),           1, '"a*" is name of second axis');
is( $space->pos_from_axis_name('b*'),           2, '"b*" is name of third axis');
is( $space->pos_from_axis_name('l'),            0, '"l" is name of first axis');
is( $space->pos_from_axis_name('a'),            1, '"a" is name of second axis');
is( $space->pos_from_axis_name('b'),            2, '"b" is name of third axis');
is( $space->pos_from_axis_name('*'),        undef, '"*" is not an axis name');
is( $space->axis_count,                         3, 'CIELAB has 3 axis');
is( $space->is_euclidean,                       1, 'CIELAB is euclidean');
is( $space->is_cylindrical,                     0, 'CIELAB is not cylindrical');

is( ref $space->check_value_shape([0, 0, 0]),          'ARRAY',   'check minimal CIELAB values are in bounds');
is( ref $space->check_value_shape([0.950, 1, 1.088]),  'ARRAY',   'check maximal CIELAB values');
is( ref $space->check_value_shape([0,0]),              '',   "CIELAB got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "CIELAB got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_value_shape([101, 0, 0]),        '',   "L value is too big");
is( ref $space->check_value_shape([0, -500.1, 0]),     '',   "a value is too small");
is( ref $space->check_value_shape([0, 500.1, 0]),      '',   "a value is too big");
is( ref $space->check_value_shape([0, 0, -200.1 ] ),   '',   "b value is too small");
is( ref $space->check_value_shape([0, 0, 200.2] ),     '',   "b value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({'L*' => 1, 'a*' => 0, 'b*' => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({l => 1, a => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({a => 1, b => 0}), 1,  'found hash with some other keys');
is( $space->is_partial_hash({a => 1, x => 0}), 0,  'partial hash with bad keys');
is( $space->can_convert('XYZ'),    1,              'do convert from and to xyz');
is( $space->can_convert('xyz'),    1,              'namespace can be written lower case');
is( $space->can_convert('CIELAB'), 0,              'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'lab(0, 0, 0)', 'can format css string');

my $lab = $space->deformat(['CIELAB', 0, -1, -0.1]);
is_tuple( $lab, [0, -1, -0.1], [qw/l a b/], 'deformat named ARRAY');
is( $space->format([0,1,0], 'css_string'), 'lab(0, 1, 0)', 'can format css string');

# black
$lab = $space->convert_from( 'XYZ', [ 0, 0, 0]);
is_tuple( $space->round( $lab, 6), [0, .5, .5], [qw/l a b/], 'convert black from XYZ');
my $xyz = $space->convert_to( 'XYZ', [ 0, 0.5, 0.5]);
is_tuple( $space->round( $xyz, 6), [0, 0, 0], [qw/X Y Z/], 'convert black back to XYZ');
$lab = $space->denormalize( [0, .5, .5] );
is_tuple( $space->round( $lab, 9), [0, 0, 0], [qw/l a b/], 'denormalize black');
$lab = $space->normalize( [0, 0, 0] );
is_tuple( $space->round( $lab, 9), [0, 0.5, 0.5], [qw/l a b/], 'normalize black');

# white
$lab = $space->convert_from( 'XYZ', [ 1, 1, 1,]);
is_tuple( $space->round( $lab, 9), [1, .5, .5], [qw/l a b/], 'convert white from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 1, 0.5, 0.5]);
is_tuple( $space->round( $xyz, 6), [1, 1, 1], [qw/X Y Z/], 'convert white back to XYZ');
$lab = $space->denormalize( [1, .5, .5] );
is_tuple( $space->round( $lab, 9), [100, 0, 0], [qw/l a b/], 'denormalize white');
$lab = $space->normalize( [100, 0, 0] );
is_tuple( $space->round( $lab, 9), [1, 0.5, 0.5], [qw/l a b/], 'normalize white');

# nice blue
$lab = $space->convert_from( 'XYZ', [ 0.0872931606914908, 0.0537065470652866, 0.282231548430505]);
is_tuple( $space->round( $lab, 5), [0.27766, 0.53316, 0.36067], [qw/l a b/], 'convert nice blue from XYZ');
$xyz = $space->convert_to( 'XYZ', [ .277656852, 0.5331557592, 0.3606718]);
is_tuple( $space->round( $xyz, 5), [0.08729, 0.05371, 0.28223], [qw/X Y Z/], 'convert nice blue back to XYZ');
$lab = $space->denormalize( [0.277656852, 0.5331557592, 0.3606718] );
is_tuple( $space->round( $lab, 5), [27.76569, 33.15576, -55.73128], [qw/l a b/], 'denormalize nice blue');
$lab = $space->normalize( [27.7656852, 33.156, -55.731] );
is_tuple( $space->round( $lab, 5), [0.27766, 0.53316, 0.36067], [qw/l a b/], 'normalize nice blue');

# pink
$lab = $space->convert_from( 'XYZ', [0.487032731, 0.25180, 0.208186769 ]);
is_tuple( $space->round( $lab, 5), [0.57250, 0.57766, 0.5194], [qw/l a b/], 'convert pink from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 0.572503826652422, 0.57765505274346, 0.519396157464772]);
is_tuple( $space->round( $xyz, 5), [0.48703, 0.25180, 0.20819], [qw/X Y Z/], 'convert pink back to XYZ');
$lab = $space->denormalize( [0.57250, 0.577658, 0.5193925] );
is_tuple( $space->round( $lab, 5), [57.250, 77.658, 7.757], [qw/l a b/], 'denormalize pink');
$lab = $space->normalize( [57.25, 77.658, 7.757] );
is_tuple( $space->round( $lab, 5), [0.57250, 0.57766, 0.51939], [qw/l a b/], 'normalize pink');

exit 0;
