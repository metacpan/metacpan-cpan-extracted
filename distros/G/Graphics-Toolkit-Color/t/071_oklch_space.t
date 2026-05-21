#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 60;

my $module = 'Graphics::Toolkit::Color::Space::Instance::OKLCH';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                         'OKLCH', 'color space name is OKLCH');
is( $space->name('alias'),                     '', 'color space has no alias name');
is( $space->is_name('OKlch'),                   1, 'color space name OKlch is correct, lc chars at will!');
is( $space->is_name('LCH'),                     0, 'color space name LCH is given to CIELCHab');
is( $space->is_axis_name('oklch'),              0, 'space name is not axis name');
is( $space->is_axis_name('luminance'),          1, '"luminance" is an axis name');
is( $space->is_axis_name('chroma'),             1, '"chroma" is an axis name');
is( $space->is_axis_name('hue'),                1, '"hue" is an axis name');
is( $space->is_axis_name('hu'),                 0, 'can not miss a lettter of axis name');
is( $space->is_axis_name('l'),                  1, '"l" is an axis name');
is( $space->is_axis_name('c'),                  1, '"u" is an axis name');
is( $space->is_axis_name('h'),                  1, '"v" is an axis name');
is( $space->pos_from_axis_name('luminance'),    0, '"luminance" is name of first axis');
is( $space->pos_from_axis_name('chroma'),       1, '"chroma" is name of second axis');
is( $space->pos_from_axis_name('hue'),          2, '"hue" is name of third axis');
is( $space->pos_from_axis_name('l'),            0, '"l" is name of first axis');
is( $space->pos_from_axis_name('c'),            1, '"c" is name of second axis');
is( $space->pos_from_axis_name('h'),            2, '"h" is name of third axis');
is( $space->pos_from_axis_name('*'),        undef, '"*" is not an axis name');
is( $space->axis_count,                         3, 'OKLCH has 3 dimensions');
is( $space->is_euclidean,                       0, 'OKLCH is not euclidean');
is( $space->is_cylindrical,                     1, 'OKLCH is cylindrical');

is( ref $space->check_value_shape([0,0]),              '',   "OKLCH got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "OKLCH got too many values");
is( ref $space->check_value_shape([0, 0, 0]),     'ARRAY',   'check minimal OKLCH values are in bounds');
is( ref $space->check_value_shape([1, 0.5, 360]), 'ARRAY',   'check maximal OKLCH values are in bounds');
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_value_shape([1.01, 0, 0]),       '',   'L value is too big');
is( ref $space->check_value_shape([0, -0.51, 0]),      '',   "c value is too small");
is( ref $space->check_value_shape([0, 0.51, 0]),       '',   'c value is too big');
is( ref $space->check_value_shape([0, 0, -0.1]),       '',   'h value is too small');
is( ref $space->check_value_shape([0, 0, 360.2] ),     '',   "h value is too big");

is( $space->is_value_tuple([0,0,0]),                      1, 'tuple has 3 elements');
is( $space->is_partial_hash({c => 1, h => 0}),            1, 'found hash with some axis names');
is( $space->is_partial_hash({l => 1, c => 0, h => 0}),    1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, 'h*' => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'OKLAB'),                        1, 'do only convert from and to OKLAB');
is( $space->can_convert( 'Lab'),                          0, 'namespace can be written lower case');
is( $space->can_convert( 'CIELCHab'),                     0, 'can not convert to itself');
is( $space->format([1.23,0,41], 'css_string'), 'oklch(1.23, 0, 41)', 'can format css string');

my $val = $space->deformat(['OKLCH', 0, -1, -0.1]);
is_tuple( $val, [0, -1, -0.1], [qw/luminance chroma hue/], 'deformated named ARRAY into tuple');
$val = $space->deformat(['OKLCH', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'space name (short) was recognized in named ARRAY format');
is( $space->format([0,11,350], 'css_string'), 'oklch(0, 11, 350)', 'can format css string');

# black
$val = $space->denormalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/luminance chroma hue/], 'denormalize black');
$val = $space->normalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/luminance chroma hue/], 'normalize black');
my $lch = $space->convert_from( 'OKLAB',  [ 0, 0.5, 0.5]);
is_tuple( $space->round( $lch, 9), [0, 0, 0], [qw/luminance chroma hue/], 'convert black from OKLAB');
my $lab = $space->convert_to( 'OKLAB',  [ 0, 0, 0 ]);
is_tuple( $space->round( $lab, 9), [0, 0.5, 0.5], [qw/l a b/], 'convert black to OKLAB');

# white
$lch = $space->convert_from( 'OKLAB',  [ 1, 0.5, 0.5]);
is_tuple( $space->round( $lch, 9), [1, 0, 0], [qw/luminance chroma hue/], 'convert white from OKLAB');
$lab = $space->convert_to( 'OKLAB',  [ 1, 0, 0 ]);
is_tuple( $space->round( $lab, 9), [1, 0.5, 0.5], [qw/l a b/], 'convert white to OKLAB');

# gray
$lch = $space->convert_from( 'OKLAB',  [ 0.59987, .5, .5]);
is_tuple( $space->round( $lch, 5), [0.59987, 0, 0], [qw/luminance chroma hue/], 'convert gray from OKLAB');
$lab = $space->convert_to( 'OKLAB',  [ .53389, 0, 0 ]);
is_tuple( $space->round( $lab, 5), [.53389, 0.5, 0.5], [qw/l a b/], 'convert gray to OKLAB');

# red
$lch = $space->convert_from( 'OKLAB',  [ 0.6279553639214311, 0.7248630684262744, 0.625846277330585]);
is_tuple( $space->round( $lch, 5), [0.62796, .51537, .08121], [qw/luminance chroma hue/], 'convert red from OKLAB');
$lab = $space->convert_to( 'OKLAB',  [ .627955364, 0.515366608, .081205223]);
is_tuple( $space->round( $lab, 5), [.62796, 0.72486, 0.62585], [qw/l a b/], 'convert red to OKLAB');

# blue
$lch = $space->convert_from( 'OKLAB',  [ 0.45201371817442365, 0.467543025, 0.188471834]);
is_tuple( $space->round( $lch, 5), [0.45201, .62643, .73348], [qw/luminance chroma hue/], 'convert blue from OKLAB');
$lab = $space->convert_to( 'OKLAB',  [ .45201371817442365, 0.626428778, .733477841 ]);
is_tuple( $space->round( $lab, 5), [.45201, 0.46754, 0.18847], [qw/l a b/], 'convert blue to OKLAB');

# green
$lch = $space->convert_from( 'OKLAB',  [ 0.5197518313867289, 0.359697668398572, 0.60767587690661445]);
is_tuple( $space->round( $lch, 5), [0.51975, .35372, .39582], [qw/luminance chroma hue/], 'convert green from OKLAB');
$lab = $space->convert_to( 'OKLAB',  [ .5197518313867289, 0.353716489, .395820403 ]);
is_tuple( $space->round( $lab, 5), [.51975, 0.3597, 0.60768], [qw/l a b/], 'convert blue to OKLAB');

exit 0;
