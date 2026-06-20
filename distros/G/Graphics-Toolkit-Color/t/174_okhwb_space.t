#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 78;

my $module = 'Graphics::Toolkit::Color::Space::Instance::OKHWB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                         'OKHWB', 'color space name is OKHWB');
is( $space->name('alias'),                     '', 'color space has no alias name');
is( $space->is_name('okHWB'),                   1, 'color space name okHWB is correct, lc chars at will!');
is( $space->is_name('HWB'),                     0, 'color space name HWB is given to OKHWB');
is( $space->family,                         'HWB', 'OKHWB space is in the HWB family');
is( $space->is_axis_name('OKHWB'),              0, 'space name is not axis name');
is( $space->is_axis_name('hue'),                1, '"hue" is an axis name');
is( $space->is_axis_name('whiteness'),          1, '"whiteness" is an axis name');
is( $space->is_axis_name('blackness'),          1, '"blackness" is an axis name');
is( $space->is_axis_name('hu'),                 0, 'can not miss a lettter of axis name');
is( $space->is_axis_name('h'),                  1, '"h" is an axis name');
is( $space->is_axis_name('w'),                  1, '"w" is an axis name');
is( $space->is_axis_name('b'),                  1, '"b" is an axis name');
is( $space->is_axis_role('hue'),                1, '"hue" is an axis role');
is( $space->is_axis_role('whiteness'),          1, '"whiteness" is an axis role');
is( $space->is_axis_role('blackness'),          1, '"blackness" is an axis role');
is( $space->is_axis_role('hu'),                 0, 'can not miss a lettter of axis role');
is( $space->is_axis_role('h'),                  1, '"h" is an axis role');
is( $space->is_axis_role('w'),                  1, '"w" is an axis role');
is( $space->is_axis_role('b'),                  1, '"b" is an axis role');
is( $space->is_axis_role('m'),                  0, '"m" is not an axis role');
is( $space->pos_from_axis_name('hue'),          0, '"hue" is name of first axis');
is( $space->pos_from_axis_name('whiteness'),    1, '"whiteness" is name of second axis');
is( $space->pos_from_axis_name('blackness'),    2, '"blackness" is name of third axis');
is( $space->pos_from_axis_name('h'),            0, '"h" is name of first axis');
is( $space->pos_from_axis_name('w'),            1, '"w" is name of second axis');
is( $space->pos_from_axis_name('b'),            2, '"b" is name of third axis');
is( $space->pos_from_axis_name('*'),        undef, '"*" is not an axis name');
is( $space->pos_from_axis_role('hue'),          0, '"hue" is role of first axis');
is( $space->pos_from_axis_role('whiteness'),    1, '"whiteness" is role of second axis');
is( $space->pos_from_axis_role('blackness'),    2, '"blackness" is role of third axis');
is( $space->pos_from_axis_role('h'),            0, '"h" is role of first axis');
is( $space->pos_from_axis_role('w'),            1, '"w" is role of second axis');
is( $space->pos_from_axis_role('b'),            2, '"b" is role of third axis');
is( $space->pos_from_axis_role('m'),        undef, '"m" is not an axis role');
is( $space->axis_count,                         3, 'OKHWB has 3 dimensions');
is( $space->is_euclidean,                       0, 'OKHWB is not euclidean');
is( $space->is_cylindrical,                     1, 'OKHWB is cylindrical');

is( ref $space->check_value_shape([0,0]),              '',   "OKHWB got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "OKHWB got too many values");
is( ref $space->check_value_shape([0, 0, 0]),     'ARRAY',   'check minimal OKHWB values are in bounds');
is( ref $space->check_value_shape([360, 1, 1]),   'ARRAY',   'check maximal OKHWB values are in bounds');
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "H value is too small");
is( ref $space->check_value_shape([360.01, 0, 0]),     '',   'H value is too big');
is( ref $space->check_value_shape([0, -0.01, 0]),      '',   "W value is too small");
is( ref $space->check_value_shape([0, 1.01, 0]),       '',   'W value is too big');
is( ref $space->check_value_shape([0, 0, -0.1]),       '',   'B value is too small');
is( ref $space->check_value_shape([0, 0, 1.2] ),       '',   "B value is too big");

is( $space->is_value_tuple([0,0,0]),                      1, 'tuple has 3 elements');
is( $space->is_partial_hash({w => 1, h => 0}),            1, 'found hash with some axis names');
is( $space->is_partial_hash({w => 1, b => 0, h => 0}),    1, 'found hash with all short axis names');
is( $space->is_partial_hash({whiteness => 1, blackness => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({b => 1, 'h*' => 0, w => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'OKHSV'),                        1, 'do only convert from and to OKHSV');
is( $space->can_convert( 'okHSV'),                        1, 'namespace can be written lower case');
is( $space->can_convert( 'OKHWB'),                        0, 'can not convert to itself');
is( $space->format([1.23,0,41], 'css_string'), 'okhwb(1.23, 0, 41)', 'can format css string');

my $val = $space->deformat(['OKHWB', 0, -1, -0.1]);
is_tuple( $val, [0, -1, -0.1], [qw/hue whiteness blackness/], 'deformated named ARRAY into tuple');
$val = $space->deformat(['OKHWB', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'space name (short) was recognized in named ARRAY format');
is( $space->format([0,1,1], 'css_string'), 'okhwb(0, 1, 1)', 'can format css string');
$val = $space->denormalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/hue whiteness blackness/], 'denormalize black (min)');
$val = $space->normalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/hue whiteness blackness/], 'normalize black (min)');
$val = $space->denormalize( [1, 1, 1] );
is_tuple( $space->round( $val, 9), [360, 1, 1], [qw/hue whiteness blackness/], 'denormalize max');
$val = $space->normalize( [360, 1, 1] );
is_tuple( $space->round( $val, 9), [1, 1, 1], [qw/hue whiteness blackness/], 'normalize max');


# black

my $hwb = $space->convert_from( 'OKHSV',  [ 0, 0, 0]);
is_tuple( $space->round( $hwb, 9), [0, 0, 1], [qw/hue whiteness blackness/], 'convert black from OKHSV');
my $hsv = $space->convert_to( 'OKHSV',  [ 0, 0, 1 ]);
is_tuple( $space->round( $hsv, 9), [0, 0, 0], [qw/hue saturation value/], 'convert black to OKHSV');

# white
$hwb = $space->convert_from( 'OKHSV',  [ 1, 0, 1]);
is_tuple( $space->round( $hwb, 9), [1, 1, 0], [qw/hue whiteness blackness/], 'convert white from OKHSV');
$hsv = $space->convert_to( 'OKHSV',  [ 1, 1, 0 ]);
is_tuple( $space->round( $hsv, 9), [1, 0, 1], [qw/hue saturation value/], 'convert white to OKHSV');

# gray
$hwb = $space->convert_from( 'OKHSV',  [ 0, 0, .5]);
is_tuple( $space->round( $hwb, 5), [ 0, 0.5, 0.5], [qw/hue whiteness blackness/], 'convert gray from OKHSV');
$hsv = $space->convert_to( 'OKHSV',  [ 0, 0.5, 0.5 ]);
is_tuple( $space->round( $hsv, 5), [ 0, 0, 0.5], [qw/hue saturation value/], 'convert gray to OKHSV');

# red
$hwb = $space->convert_from( 'OKHSV',  [ 0, 1, 1]);
is_tuple( $space->round( $hwb, 5), [ 0, 0, 0], [qw/hue whiteness blackness/], 'convert red from OKHSV');
$hsv = $space->convert_to( 'OKHSV',  [ 0, 0, 0]);
is_tuple( $space->round( $hsv, 5), [ 0, 1, 1], [qw/hue saturation value/], 'convert red to OKHSV');

# blue
$hwb = $space->convert_from( 'OKHSV',  [ 1/3, 1, 1]);
is_tuple( $space->round( $hwb, 7), [0.3333333, 0, 0], [qw/hue whiteness blackness/], 'convert blue from OKHSV');
$hsv = $space->convert_to( 'OKHSV',  [ 1/3, 0, 0 ]);
is_tuple( $space->round( $hsv, 7), [.3333333, 1, 1], [qw/hue saturation value/], 'convert blue to OKHSV');

# dark red
$hwb = $space->convert_from( 'OKHSV',  [0.1, 0.15, 0.98]);
is_tuple( $space->round( $hwb, 7), [0.1, .833, .02], [qw/hue whiteness blackness/], 'convert dark red from OKHSV');
$hsv = $space->convert_to( 'OKHSV',  [0.1, .833, .02]);
is_tuple( $space->round( $hsv, 5), [.1, 0.15, 0.98], [qw/hue saturation value/], 'convert dark red to OKHSV');


exit 0;
