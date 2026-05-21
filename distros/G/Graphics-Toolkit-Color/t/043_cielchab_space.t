#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 71;

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELCHab';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'LCH', 'color space name is LCH');
is( $space->name('alias'),             'CIELCHAB', 'color space name alias name is CIELCHab');
is( $space->is_name('CIELCHab'),                1, 'color space name CIELCHab is correct');
is( $space->is_name('LCH'),                     1, 'color space name LCH is correct');
is( $space->is_name('hab'),                     0, 'color space name LCH is correct');
is( $space->is_axis_name('lchab'),              0, 'space name is not axis name');
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
is( $space->axis_count,                         3, 'LCH has 3 dimensions');
is( $space->is_euclidean,                       0, 'LCH is not euclidean');
is( $space->is_cylindrical,                     1, 'LCH is cylindrical');

is( ref $space->check_value_shape([0,0]),             '',   "CIELCHab got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),      '',   "CIELCHab got too many values");
is( ref $space->check_value_shape([0, 0, 0]),         'ARRAY',   'check minimal CIELCHab values are in bounds');
is( ref $space->check_value_shape([100, 539, 360]),   'ARRAY',   'check maximal CIELCHab values are in bounds');
is( ref $space->check_value_shape([-0.1, 0, 0]),      '',   "L value is too small");
is( ref $space->check_value_shape([100.01, 0, 0]),    '',   'L value is too big');
is( ref $space->check_value_shape([0, -0.1, 0]),      '',   "c value is too small");
is( ref $space->check_value_shape([0, 539.1, 0]),     '',   'c value is too big');
is( ref $space->check_value_shape([0, 0, -0.1]),      '',   'h value is too small');
is( ref $space->check_value_shape([0, 0, 360.2] ),    '',   "h value is too big");

is( $space->is_value_tuple([0,0,0]),                   1,  'tuple has 3 elements');
is( $space->is_partial_hash({c => 1, h => 0}),         1,  'found hash with some axis names');
is( $space->is_partial_hash({l => 1, c => 0, h => 0}), 1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'LAB'),                       1, 'do only convert from and to CIELAB');
is( $space->can_convert( 'Lab'),                       1, 'namespace can be written lower case');
is( $space->can_convert( 'CIELCHab'),                  0, 'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'lch(0, 0, 0)','can format css string');

my $val = $space->deformat(['CIELCHab', 0, -1, -0.1]);
is_tuple( $val, [0, -1, -0.1], [qw/luminance chroma hue/], 'deformated named ARRAY into tuple');
$val = $space->deformat(['LCH', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'space name (short) was recognized in named ARRAY format');
is( $space->format([0,11,350], 'css_string'), 'lch(0, 11, 350)', 'can format css string');

# black
$val = $space->denormalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/luminance chroma hue/], 'denormalize black');
$val = $space->normalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/luminance chroma hue/], 'normalize black');
my $lch = $space->convert_from( 'LAB',  [ 0, 0.5, 0.5]);
is_tuple( $space->round( $lch, 5), [0, 0, 0], [qw/luminance chroma hue/], 'convert black from LAB');
my $lab = $space->convert_to( 'LAB',  [ 0, 0, 0 ]);
is_tuple( $space->round( $lab, 5), [0, 0.5, 0.5], [qw/l a b/], 'convert black to LAB');

# white
$val = $space->denormalize( [1, 0, 0] );
is_tuple( $space->round( $val, 9), [100, 0, 0], [qw/luminance chroma hue/], 'denormalize white');
$val = $space->normalize( [100, 0, 0] );
is_tuple( $space->round( $val, 9), [1, 0, 0], [qw/luminance chroma hue/], 'normalize white');
$lch = $space->convert_from( 'LAB',  [ 1, .5, .5]);
is_tuple( $space->round( $lch, 5), [1, 0, 0], [qw/luminance chroma hue/], 'convert white from LAB');
$lab = $space->convert_to( 'LAB',  [ 1, 0, 0 ]);
is_tuple( $space->round( $lab, 5), [1, 0.5, 0.5], [qw/l a b/], 'convert white to LAB');

# gray
$val = $space->denormalize( [.53389, 0, .686386111] );
is_tuple( $space->round( $val, 5), [53.389, 0, 247.099], [qw/luminance chroma hue/], 'denormalize gray');
$val = $space->normalize( [53.389, 0, 247.099] );
is_tuple( $space->round( $val, 5), [.53389, 0, 0.68639], [qw/luminance chroma hue/], 'normalize gray');
$lch = $space->convert_from( 'LAB',  [ .53389, .5, .5]);
is_tuple( $space->round( $lch, 5), [.53389, 0, 0], [qw/luminance chroma hue/], 'convert gray from LAB');
$lab = $space->convert_to( 'LAB',  [ .53389, 0, 0.686386111 ]);
is_tuple( $space->round( $lab, 5), [.53389, 0.5, 0.5], [qw/l a b/], 'convert gray to LAB');

# red
$val = $space->denormalize( [.53389, 0.193974026, .111108333] );
is_tuple( $space->round( $val, 5), [53.389, 104.552, 39.999], [qw/luminance chroma hue/], 'denormalize red');
$val = $space->normalize( [53.389, 104.552, 39.999] );
is_tuple( $space->round( $val, 5), [.53389, 0.19397, 0.11111], [qw/luminance chroma hue/], 'normalize red');
$lch = $space->convert_from( 'LAB',  [ .53389, .580092, .6680075]);
is_tuple( $space->round( $lch, 5), [.53389, .19397, .11111], [qw/luminance chroma hue/], 'convert red from LAB');
$lab = $space->convert_to( 'LAB',  [ .53389, 0.193974026, .111108333 ]);
is_tuple( $space->round( $lab, 5), [.53389, 0.58009, 0.66801], [qw/l a b/], 'convert red to LAB');

# blue
$val = $space->denormalize( [.32297, 0.248252319, .850791667] );
is_tuple( $space->round( $val, 5), [32.297, 133.808, 306.285], [qw/luminance chroma hue/], 'denormalize blue');
$val = $space->normalize( [32.297, 133.808, 306.285] );
is_tuple( $space->round( $val, 5), [.32297, 0.24825, 0.85079], [qw/luminance chroma hue/], 'normalize blue');
$lch = $space->convert_from( 'LAB',  [ .32297, .579188, .23035]);
is_tuple( $space->round( $lch, 5), [.32297, .24825, .85079], [qw/luminance chroma hue/], 'convert blue from LAB');
$lab = $space->convert_to( 'LAB',  [ .32297, 0.248252319, .850791667 ]);
is_tuple( $space->round( $lab, 5), [.32297, 0.57919, 0.23035], [qw/l a b/], 'convert blue to LAB');

# mid blue
$val = $space->denormalize( [.37478, 0.220141002, .842422222] );
is_tuple( $space->round( $val, 5), [37.478, 118.656, 303.272], [qw/luminance chroma hue/], 'denormalize mid blue');
$val = $space->normalize( [37.478, 118.656, 303.272] );
is_tuple( $space->round( $val, 5), [.37478, 0.22014, 0.84242], [qw/luminance chroma hue/], 'normalize mid blue');
$lch = $space->convert_from( 'LAB',  [ .37478, .565097, .2519875]);
is_tuple( $space->round( $lch, 5), [.37478, .22014, .84242], [qw/luminance chroma hue/], 'convert mid blue from LAB');
$lab = $space->convert_to( 'LAB',  [ .37478, 0.220141002, .842422222 ]);
is_tuple( $space->round( $lab, [5,4,5]), [.37478, 0.5651, 0.25199], [qw/l a b/], 'convert mid blue to LAB');

exit 0;
