#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 82;

my $module = 'Graphics::Toolkit::Color::Space::Instance::OKHSL';
my $space = eval "require $module";
is( not($@), 1, 'could load the module'); #say $@; exit 0;
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                         'OKHSL', 'color space name is OKHSL');
is( $space->name('alias'),                     '', 'color space has no alias name');
is( $space->is_name('okHSL'),                   1, 'color space name OKHSL is correct, lc chars at will!');
is( $space->is_name('HSL'),                     0, 'color space name HSL is given to HSL');
is( $space->family,                         'HSL', 'OKHSL space is in the HSL family');
is( $space->is_axis_name('okHSL'),              0, 'space name is not axis name');
is( $space->is_axis_name('hue'),                1, '"hue" is an axis name');
is( $space->is_axis_name('saturation'),         1, '"saturation" is an axis name');
is( $space->is_axis_name('lightness'),          1, '"lightness" is an axis name');
is( $space->is_axis_name('hu'),                 0, 'can not miss a lettter of axis name');
is( $space->is_axis_name('h'),                  1, '"h" is an axis name');
is( $space->is_axis_name('s'),                  1, '"a" is an axis name');
is( $space->is_axis_name('l'),                  1, '"l" is an axis name');
is( $space->is_axis_name('m'),                  0, '"m" is not an axis name');
is( $space->is_axis_role('hue'),                1, '"hue" is an axis role');
is( $space->is_axis_role('saturation'),         1, '"saturation" is an axis role');
is( $space->is_axis_role('lightness'),          1, '"lightness" is an axis role');
is( $space->is_axis_role('hu'),                 0, 'can not miss a lettter of axis role');
is( $space->is_axis_role('h'),                  1, '"h" is an axis role');
is( $space->is_axis_role('s'),                  1, '"s" is an axis role');
is( $space->is_axis_role('l'),                  1, '"l" is an axis role');
is( $space->is_axis_role('m'),                  0, '"m" is not an axis role');
is( $space->pos_from_axis_name('hue'),          0, '"hue" is name of first axis');
is( $space->pos_from_axis_name('saturation'),   1, '"saturation" is name of second axis');
is( $space->pos_from_axis_name('lightness'),    2, '"lightness" is name of third axis');
is( $space->pos_from_axis_name('h'),            0, '"h" is name of first axis');
is( $space->pos_from_axis_name('s'),            1, '"s" is name of second axis');
is( $space->pos_from_axis_name('l'),            2, '"l" is name of third axis');
is( $space->pos_from_axis_name('m'),        undef, '"m" is not an axis name');
is( $space->pos_from_axis_role('hue'),          0, '"hue" is role of first axis');
is( $space->pos_from_axis_role('saturation'),   1, '"saturation" is role of second axis');
is( $space->pos_from_axis_role('lightness'),    2, '"lightness" is role of third axis');
is( $space->pos_from_axis_role('h'),            0, '"h" is role of first axis');
is( $space->pos_from_axis_role('s'),            1, '"s" is role of second axis');
is( $space->pos_from_axis_role('l'),            2, '"l" is role of third axis');
is( $space->pos_from_axis_role('m'),        undef, '"m" is not an axis role');
is( $space->axis_count,                         3, 'OKHSL has 3 dimensions');
is( $space->is_euclidean,                       0, 'OKHSL is not euclidean');
is( $space->is_cylindrical,                     1, 'OKHSL is cylindrical');
is( $space->shape->has_constraints,             0, 'OKHSL is a full cylinder');

is( ref $space->check_value_shape([0,0]),              '',   "OKHSL got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "OKHSL got too many values");
is( ref $space->check_value_shape([0, 0, 0]),     'ARRAY',   'check minimal OKHSL values are in bounds');
is( ref $space->check_value_shape([360, 1, 1]),   'ARRAY',   'check maximal OKHSL values are in bounds');
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "H value is too small");
is( ref $space->check_value_shape([360.01, 0, 0]),     '',   'H value is too big');
is( ref $space->check_value_shape([0, -0.01, 0]),      '',   "S value is too small");
is( ref $space->check_value_shape([0, 1.01, 0]),       '',   'S value is too big');
is( ref $space->check_value_shape([0, 0, -0.1]),       '',   'L value is too small');
is( ref $space->check_value_shape([0, 0, 1.2] ),       '',   "L value is too big");

is( $space->is_value_tuple([0,0,0]),                      1, 'tuple has 3 elements');
is( $space->is_partial_hash({h => 1, l => 0}),            1, 'found hash with some axis names');
is( $space->is_partial_hash({l => 1, s => 0, h => 0}),    1, 'found hash with all short axis names');
is( $space->is_partial_hash({hue => 1, saturation => 0, lightness => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, 'h*' => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'LinearRGB'),                    1, 'do only convert from and to LinearRGB');
is( $space->can_convert( 'XYZ'),                          0, 'XYZ ist not converter arent');
is( $space->can_convert( 'OKHSL'),                        0, 'can not convert to itself');
is( $space->format([1.23,0,.41], 'css_string'), 'okhsl(1.23, 0, 0.41)', 'can format css string');

my $val = $space->deformat(['OKHSL', 0, -1, -0.1]);
is_tuple( $val, [0, -1, -0.1], [qw/hue saturation lightness/], 'deformated named ARRAY into tuple');
$val = $space->deformat(['OKHSL', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'space name (short) was recognized in named ARRAY format');
is( $space->format([0,11,350], 'css_string'), 'okhsl(0, 11, 350)', 'can format css string');

# black
$val = $space->denormalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/hue saturation lightness/], 'denormalize black');
$val = $space->normalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/hue saturation lightness/], 'normalize black');
my $hsl = $space->convert_from( 'LinearRGB',  [ 0, 0, 0]);
is_tuple( $space->round( $hsl, 9), [0, 0, 0], [qw/hue saturation lightness/], 'convert black from LinearRGB');
my $rgb = $space->convert_to( 'LinearRGB',  [ 0, 0, 0 ]);
is_tuple( $space->round( $rgb, 9), [0, 0, 0], [qw/red green blue/], 'convert black to LinearRGB');

# white
$hsl = $space->convert_from( 'LinearRGB',  [ 1, 1, 1]);
is( $space->round( $hsl, [9,9,7])->[2], 1, 'convert white from LinearRGB needs to have a lightness of 1');
$rgb = $space->convert_to( 'LinearRGB', $hsl);
is_tuple( $space->round( $rgb, 7), [1, 1, 1], [qw/red green blue/], 'convert white to LinearRGB');

# gray
$hsl = $space->convert_from( 'LinearRGB',  [ 0.21404114, .21404114, .21404114]);
is( $space->round( $hsl, [9,9,6])->[2], 0.53376, 'convert mid gray from LinearRGB needs to have a lightness of 0.53376');
$rgb = $space->convert_to( 'LinearRGB', $hsl);
is_tuple( $space->round( $rgb, 6), [0.214041, .214041, .214041], [qw/red green blue/], 'convert gray to LinearRGB');

# red
$hsl = $space->convert_from( 'LinearRGB',  [ 1, 0, 0]);
is_tuple( $space->round( $hsl, [7,7,6]), [0.0812052, 1, .568085], [qw/hue saturation lightness/], 'convert red from LinearRGB');
$rgb = $space->convert_to( 'LinearRGB', $hsl);
is_tuple( $space->round( $rgb, [8,8,7]), [1, 0, 0], [qw/red green blue/], 'convert red to LinearRGB');

# green
$hsl = $space->convert_from( 'LinearRGB',  [ 0, 1, 0]);
is_tuple( $space->round( $hsl, [6,7,7]), [0.395820, 1, .844529], [qw/hue saturation lightness/], 'convert green from LinearRGB');
$rgb = $space->convert_to( 'LinearRGB', $hsl);
is_tuple( $space->round( $rgb, [6,7,6]), [ 0, 1, 0], [qw/red green blue/], 'convert green to LinearRGB');

# blue
$hsl = $space->convert_from( 'LinearRGB',  [ 0, 0, 1]);
is_tuple( $space->round( $hsl, [7,7,6]), [0.7334778, 1, .366565], [qw/hue saturation lightness/], 'convert blue from LinearRGB');
$rgb = $space->convert_to( 'LinearRGB',  $hsl);
is_tuple( $space->round( $rgb, 5), [ 0, 0, 1], [qw/red green blue/], 'convert blue to LinearRGB');

# nice blue
$hsl = $space->convert_from( 'LinearRGB', [0.01, 0.2, 0.8]);
is_tuple( $space->round( $hsl, [7,6,6]), [.709042, .952931, .525716], [qw/hue saturation lightness/], 'convert nice blue from LinearRGB');
$rgb = $space->convert_to( 'LinearRGB', $hsl);
is_tuple( $space->round( $rgb, [7,7,6]), [0.01, 0.2, 0.8], [qw/red green blue/], 'convert nice blue to LinearRGB');

# dark red
$hsl = $space->convert_from( 'LinearRGB',  [0.95, 0.7, 0.6]);
is_tuple( $space->round( $hsl, [6,6,6]), [0.128209, .698498, .895443], [qw/hue saturation lightness/], 'convert dark red from LinearRGB');
$rgb = $space->convert_to( 'LinearRGB', $hsl);
is_tuple( $space->round( $rgb, [6,7,6]), [0.95, 0.7, 0.6], [qw/red green blue/], 'convert dark red to LinearRGB');

exit 0;
