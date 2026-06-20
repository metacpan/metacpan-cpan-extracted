#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 80;

my $module = 'Graphics::Toolkit::Color::Space::Instance::OKHSV';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                         'OKHSV', 'color space name is OKHSV');
is( $space->name('alias'),                     '', 'color space has no alias name');
is( $space->is_name('OKHSV'),                   1, 'color space name OKHSV is correct, lc chars at will!');
is( $space->is_name('HSV'),                     0, 'color space name HSV is not OKHSV');
is( $space->family,                         'HSV', 'OKHSV space is in the HSV family');
is( $space->is_axis_name('OKHSV'),              0, 'space name is not axis name');
is( $space->is_axis_name('hue'),                1, '"hue" is an axis name');
is( $space->is_axis_name('saturation'),         1, '"saturation" is an axis name');
is( $space->is_axis_name('value'),              1, '"value" is an axis name');
is( $space->is_axis_name('hu'),                 0, 'can not miss a lettter of axis name');
is( $space->is_axis_name('h'),                  1, '"h" is an axis name');
is( $space->is_axis_name('s'),                  1, '"s" is an axis name');
is( $space->is_axis_name('v'),                  1, '"v" is an axis name');
is( $space->is_axis_role('hue'),                1, '"hue" is an axis role');
is( $space->is_axis_role('saturation'),         1, '"saturation" is an axis role');
is( $space->is_axis_role('value'),              1, '"value" is an axis role');
is( $space->is_axis_role('hu'),                 0, 'can not miss a lettter of axis role');
is( $space->is_axis_role('h'),                  1, '"h" is an axis role');
is( $space->is_axis_role('s'),                  1, '"a" is an axis role');
is( $space->is_axis_role('v'),                  1, '"v" is an axis role');
is( $space->is_axis_role('m'),                  0, '"m" is not an axis role');
is( $space->pos_from_axis_name('hue'),          0, '"hue" is name of first axis');
is( $space->pos_from_axis_name('saturation'),   1, '"saturation" is name of second axis');
is( $space->pos_from_axis_name('value'),        2, '"value" is name of third axis');
is( $space->pos_from_axis_name('h'),            0, '"h" is name of first axis');
is( $space->pos_from_axis_name('s'),            1, '"s" is name of second axis');
is( $space->pos_from_axis_name('v'),            2, '"v" is name of third axis');
is( $space->pos_from_axis_name('g'),        undef, '"g" is not an axis name');
is( $space->pos_from_axis_role('hue'),          0, '"hue" is role of first axis');
is( $space->pos_from_axis_role('saturation'),   1, '"saturation" is role of second axis');
is( $space->pos_from_axis_role('value'),        2, '"value" is role of third axis');
is( $space->pos_from_axis_role('h'),            0, '"h" is role of first axis');
is( $space->pos_from_axis_role('s'),            1, '"s" is role of second axis');
is( $space->pos_from_axis_role('v'),            2, '"v" is role of third axis');
is( $space->pos_from_axis_role('m'),        undef, '"m" is not an axis role');
is( $space->axis_count,                         3, 'OKHSV has 3 dimensions');
is( $space->is_euclidean,                       0, 'OKHSV is not euclidean');
is( $space->is_cylindrical,                     1, 'OKHSV is cylindrical');

is( ref $space->check_value_shape([0,0]),              '',   "OKHSV got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "OKHSV got too many values");
is( ref $space->check_value_shape([0, 0, 0]),     'ARRAY',   'check minimal OKHSV values are in bounds');
is( ref $space->check_value_shape([360, 1, 1]),   'ARRAY',   'check maximal OKHSV values are in bounds');
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "H value is too small");
is( ref $space->check_value_shape([360.01, 0, 0]),     '',   'H value is too big');
is( ref $space->check_value_shape([0, -0.01, 0]),      '',   "S value is too small");
is( ref $space->check_value_shape([0, 1.01, 0]),       '',   'S value is too big');
is( ref $space->check_value_shape([0, 0, -0.1]),       '',   'V value is too small');
is( ref $space->check_value_shape([0, 0, 1.2] ),       '',   "V value is too big");

is( $space->is_value_tuple([0,0,0]),                      1, 'tuple has 3 elements');
is( $space->is_partial_hash({v => 1, h => 0}),            1, 'found hash with some axis names');
is( $space->is_partial_hash({s => 1, v => 0, h => 0}),    1, 'found hash with all short axis names');
is( $space->is_partial_hash({saturation => 1, value => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({s => 1, 'h*' => 0, v => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'LinearRGB'),                    1, 'do only convert from and to OKLAB');
is( $space->can_convert( 'Lab'),                          0, 'namespace can be written lower case');
is( $space->can_convert( 'OKHSV'),                        0, 'can not convert to itself');
is( $space->format([1.23,0,41], 'css_string'), 'okhsv(1.23, 0, 41)', 'can format css string');

my $val = $space->deformat(['OKHSV', 0, -1, -0.1]);
is_tuple( $val, [0, -1, -0.1], [qw/hue saturation value/], 'deformated named ARRAY into tuple');
$val = $space->deformat(['OKHSV', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'space name (short) was recognized in named ARRAY format');
is( $space->format([0,11,350], 'css_string'), 'okhsv(0, 11, 350)', 'can format css string');

# black
$val = $space->denormalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/hue saturation value/], 'denormalize black');
$val = $space->normalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/hue saturation value/], 'normalize black');
my $hsv = $space->convert_from( 'LinearRGB',  [ 0, 0, 0]);
is_tuple( $space->round( $hsv, 9), [0, 0, 0], [qw/hue saturation value/], 'convert black from LinearRGB');
my $rgb = $space->convert_to( 'LinearRGB',  [ 0, 0, 0 ]);
is_tuple( $space->round( $rgb, 9), [0, 0, 0], [qw/red green blue/], 'convert black to LinearRGB');

# white
$hsv = $space->convert_from( 'LinearRGB',  [ 1, 1, 1]);
is( $space->round( $hsv, [9,9,7])->[2], 1, 'convert white from LinearRGB needs to have a value of 1');
$rgb = $space->convert_to( 'LinearRGB', $hsv);
is_tuple( $space->round( $rgb, [6,7,6]), [1, 1, 1], [qw/red green blue/], 'convert white to LinearRGB');

# gray
$hsv = $space->convert_from( 'LinearRGB',  [ 0.21404114, .21404114, .21404114]);
is( $space->round( $hsv, [9,9,7])->[2], 0.5337598, 'convert mid gray from LinearRGB needs to have a value of 0.53376');
$rgb = $space->convert_to( 'LinearRGB', $hsv);
is_tuple( $space->round( $rgb, [6,6,6]), [0.214041, .214041, .214041], [qw/red green blue/], 'convert midgray to LinearRGB');

# red
$hsv = $space->convert_from( 'LinearRGB',  [ 1, 0, 0]);
is_tuple( $space->round( $hsv, [7,7,7]), [0.0812052, 0.9995220, 1.0000000], [qw/hue saturation value/], 'convert red from LinearRGB');
$rgb = $space->convert_to( 'LinearRGB', $hsv);
is_tuple( $space->round( $rgb, [8,8,7]), [1, 0, 0], [qw/red green blue/], 'convert red to LinearRGB');

# green
$hsv = $space->convert_from( 'LinearRGB',  [ 0, 1, 0]);
is_tuple( $space->round( $hsv, [7,7,7]), [0.3958204, 0.9999997, 1.0000000], [qw/hue saturation value/], 'convert green from LinearRGB');
$rgb = $space->convert_to( 'LinearRGB', $hsv);
is_tuple( $space->round( $rgb, [6,7,6]), [ 0, 1, 0], [qw/red green blue/], 'convert green to LinearRGB');

# blue
$hsv = $space->convert_from( 'LinearRGB',  [ 0, 0, 1]);
is_tuple( $space->round( $hsv, [7,7,7]), [0.7334778, 0.9999911, 1.0000000], [qw/hue saturation value/], 'convert blue from LinearRGB');
$rgb = $space->convert_to( 'LinearRGB',  $hsv);
is_tuple( $space->round( $rgb, [7,7,6]), [ 0, 0, 1], [qw/red green blue/], 'convert blue to LinearRGB');

# nice blue
$hsv = $space->convert_from( 'LinearRGB', [0.01, 0.2, 0.8]);
is_tuple( $space->round( $hsv, [7,7,7]), [0.7090420, 0.9483452, 0.9105903], [qw/hue saturation value/], 'convert nice blue from LinearRGB');
$rgb = $space->convert_to( 'LinearRGB', $hsv);
is_tuple( $space->round( $rgb, [7,7,6]), [0.01, 0.2, 0.8], [qw/red green blue/], 'convert nice blue to LinearRGB');

# dark red
$hsv = $space->convert_from( 'LinearRGB',  [0.95, 0.7, 0.6]);
is_tuple( $space->round( $hsv, [7,7,7]), [0.1282093, 0.1544353, 0.9800814], [qw/hue saturation value/], 'convert dark red from LinearRGB');
$rgb = $space->convert_to( 'LinearRGB', $hsv);
is_tuple( $space->round( $rgb, [6,7,6]), [0.95, 0.7, 0.6], [qw/red green blue/], 'convert dark red to LinearRGB');

exit 0;
