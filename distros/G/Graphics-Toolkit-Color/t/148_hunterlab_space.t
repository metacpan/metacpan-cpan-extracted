#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 56;

my $module = 'Graphics::Toolkit::Color::Space::Instance::HunterLAB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                     'HUNTERLAB', 'color space official name is "HUNTERLAB"');
is( $space->name('alias'),                     '', 'no color space alias name');
is( $space->is_name('HunterLAB'),               1, 'color space name HunterLAB is correct');
is( $space->is_name('CIElab'),                  0, 'not to be confused with "CIELAB"');
is( $space->is_name('lab'),                     0, 'axis initials do not equal space name this time');
is( $space->is_axis_name('*'),                  0, 'can not miss a lettter of axis name');
is( $space->is_axis_name('l'),                  1, '"l" is an axis name');
is( $space->is_axis_name('a'),                  1, '"a" is an axis name');
is( $space->is_axis_name('b'),                  1, '"b" is an axis name');
is( $space->pos_from_axis_name('l'),            0, '"l" is name of first axis');
is( $space->pos_from_axis_name('a'),            1, '"a" is name of second axis');
is( $space->pos_from_axis_name('b'),            2, '"b" is name of third axis');
is( $space->pos_from_axis_name('*'),        undef, '"*" is not an axis name');
is( $space->axis_count,                         3, 'HunterLAB has 3 axis');
is( $space->is_euclidean,                       1, 'HunterLAB is euclidean');
is( $space->is_cylindrical,                     0, 'HunterLAB is not cylindrical');

# K: 172,355206019 67,038696071
is( ref $space->check_value_shape([0, -172.30, -67.03]),'ARRAY',  'check minimal HunterLAB values are in bounds');
is( ref $space->check_value_shape([100, 172.30, 67.03]),'ARRAY',  'check maximal HunterLAB values');
is( ref $space->check_value_shape([0,0]),              '',   "HunterLAB got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "HunterLAB got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_value_shape([101, 0, 0]),        '',   "L value is too big");
is( ref $space->check_value_shape([1, -172.4, 0]),     '',   "a value is too small");
is( ref $space->check_value_shape([1, 172.4, 0]),      '',   "a value is too big");
is( ref $space->check_value_shape([0, 0, -67.21 ] ),   '',   "b value is too small");
is( ref $space->check_value_shape([0, 0, 67.21] ),     '',   "b value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({'L' => 1, 'a' => 0, 'b' => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({'L' => 1, 'a' => 0, 'b*' => 0}), 0, 'not confused with lab Hash');
is( $space->is_partial_hash({l => 1, a => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({a => 1, b => 0}), 1,  'found hash with some other keys');
is( $space->is_partial_hash({a => 1, x => 0}), 0,  'partial hash with bad keys');
is( $space->can_convert('XYZ'),    1,              'do convert from and to xyz');
is( $space->can_convert('xyz'),    1,              'namespace can be written lower case');
is( $space->can_convert('HunterLAB'), 0,           'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'hunterlab(0, 0, 0)', 'can format css string');

my $lab = $space->deformat(['HunterLAB', 100, 0, -67.1]);
is_tuple( $space->round( $lab, 6), [100, 0, -67.1], [qw/l a b/], 'deformat named ARRAY');
is( $space->format([11.1, 5, 0], 'named_string'), 'hunterlab: 11.1, 5, 0', 'can format named string');

# black
$lab = $space->convert_from( 'XYZ', [ 0, 0, 0]);
is_tuple( $space->round( $lab, 9), [ 0, 0.5, .5], [qw/l a b/], 'conver black from XYZ');
my $xyz = $space->convert_to( 'XYZ', [ 0, 0.5, 0.5]);
is_tuple( $space->round($xyz, 9), [ 0, 0, 0], [qw/X Y Z/], 'conver black back to XYZ');
$lab = $space->denormalize( [0, .5, .5] );
is_tuple( $space->round( $lab, 9), [ 0, 0, 0], [qw/l a b/], 'denormalize black');
$lab = $space->normalize( [0, 0, 0] );
is_tuple( $space->round( $lab, 9), [ 0, 0.5, 0.5], [qw/l a b/], 'normalize black');

# white
$lab = $space->convert_from( 'XYZ', [ 1, 1, 1,]);
is_tuple( $space->round( $lab, 9), [ 1, 0.5, .5], [qw/l a b/], 'conver white from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 1, 0.5, 0.5]);
is_tuple( $space->round($xyz, 9), [ 1, 1, 1], [qw/X Y Z/], 'conver white back to XYZ');
$lab = $space->denormalize( [1, .5, .5] );
is_tuple( $space->round( $lab, 9), [ 100, 0, 0], [qw/l a b/], 'denormalize white');
$lab = $space->normalize( [100, 0, 0] );
is_tuple( $space->round( $lab, 9), [ 1, 0.5, 0.5], [qw/l a b/], 'normalize white');

# nice blue
$lab = $space->convert_from( 'XYZ', [ 0.08729316023, 0.053706547, 0.28223099106]);
is_tuple( $space->round( $lab, 5), [ .23175, .57246, .00695], [qw/l a b/], 'conver nice blue from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 0.231746730289771, 0.57246405, 0.006952172]);
is_tuple( $space->round($xyz, 5), [ 0.08729, 0.05371, 0.28223], [qw/X Y Z/], 'conver nice blue back to XYZ');
$lab = $space->denormalize( [0.231746730289771, 0.57246405, 0.006952172] );
is_tuple( $space->round( $lab, [5,3,3]), [ 23.17467, 24.979, -66.107], [qw/l a b/], 'denormalize nice blue');
$lab = $space->normalize( [23.17467, 24.979, -66.107] );
is_tuple( $space->round( $lab, 5), [ 0.23175, 0.57246, 0.00695], [qw/l a b/], 'normalize nice blue');

# pink
$lab = $space->convert_from( 'XYZ', [0.487032731, 0.25180, 0.208186769 ]);
is_tuple( $space->round( $lab, 5), [ .50180, .73439, .54346], [qw/l a b/], 'conver pink from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 0.501796772, 0.734390439, 0.543457066]);
is_tuple( $space->round($xyz, 5), [ 0.48703, 0.25180, 0.20819], [qw/X Y Z/], 'conver pink back to XYZ');
$lab = $space->denormalize( [0.501796772, 0.734390439, 0.543457066] );
is_tuple( $space->round( $lab, 3), [ 50.180, 80.797, 5.827], [qw/l a b/], 'denormalize pink');
$lab = $space->normalize( [50.180, 80.797, 5.827] );
is_tuple( $space->round( $lab, 5), [ 0.50180, 0.73439, 0.54346], [qw/l a b/], 'normalize pink');

exit 0;
