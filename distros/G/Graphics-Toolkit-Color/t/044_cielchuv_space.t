#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 70;

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELCHuv';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                      'CIELCHUV', 'color space name is CIELCHuv');
is( $space->name('alias'),                'LCHUV', 'color space has alias name: LCHuv');
is( $space->is_name('CIELCHuv'),                1, 'color space name CIELCHuv is correct');
is( $space->is_name('LCHuv'),                   1, 'color space name LCHuv is correct');
is( $space->is_name('LCH'),                     0, 'LCH is given for another space');
is( $space->is_axis_name('lchuv'),              0, 'space name is not axis name');
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
is( $space->axis_count,                         3, 'LCHUV has 3 dimensions');
is( $space->is_euclidean,                       0, 'LCHUV is not euclidean');
is( $space->is_cylindrical,                     1, 'LCHUV is cylindrical');

is( ref $space->check_value_shape( [0,0]),              '',   "CIELCHuv got too few values");
is( ref $space->check_value_shape( [0, 0, 0, 0]),       '',   "CIELCHuv got too many values");
is( ref $space->check_value_shape( [0, 0, 0]),          'ARRAY',   'check minimal CIELCHuv values are in bounds');
is( ref $space->check_value_shape( [100, 261, 360]),    'ARRAY',   'check maximal CIELCHuv values are in bounds');
is( ref $space->check_value_shape( [-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_value_shape( [100.01, 0, 0]),     '',   'L value is too big');
is( ref $space->check_value_shape( [0, -0.1, 0]),       '',   "c value is too small");
is( ref $space->check_value_shape( [0, 261.1, 0]),      '',   'c value is too big');
is( ref $space->check_value_shape( [0, 0, -0.1]),       '',   'h value is too small');
is( ref $space->check_value_shape( [0, 0, 360.2] ),     '',   "h value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({c => 1, h => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({l => 1, c => 0, h => 0}), 1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert('LUV'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('Luv'), 1,                 'namespace can be written lower case');
is( $space->can_convert('CIELCHuv'), 0,               'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'cielchuv(0, 0, 0)', 'can format css string');

my $lch = $space->deformat(['CIELCHuv', 0, -1, -0.1]);
is_tuple( $lch, [0, -1, -0.1], [qw/luminance chroma hue/], 'deformated named ARRAY into tuple');
is( $space->format([0,1,0], 'css_string'), 'cielchuv(0, 1, 0)', 'can format css string');

# black
my$val = $space->denormalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/luminance chroma hue/], 'denormalize black');
$val = $space->normalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/luminance chroma hue/], 'normalize black');
$lch = $space->convert_from( 'LUV', [ 0, .378531073, .534351145]);
is_tuple( $space->round( $lch, 5), [0, 0, 0], [qw/luminance chroma hue/], 'convert black from LUV');
my $luv = $space->convert_to( 'LUV', [ 0, 0, 0 ] );
is_tuple( $space->round( $luv, 5), [0, 0.37853, 0.53435], [qw/l u v/], 'convert black to LUV');

# white
$val = $space->denormalize( [1, 0, 0] );
is_tuple( $space->round( $val, 9), [100, 0, 0], [qw/luminance chroma hue/], 'denormalize white');
$val = $space->normalize( [100, 0, 0] );
is_tuple( $space->round( $val, 9), [1, 0, 0], [qw/luminance chroma hue/], 'normalize white');
$lch = $space->convert_from( 'LUV', [ 1, .378531073, .534351145]);
is_tuple( $space->round( $lch, 5), [1, 0, 0], [qw/luminance chroma hue/], 'convert white from LUV');
$luv = $space->convert_to( 'LUV', [ 1, 0, 0 ] );
is_tuple( $space->round( $luv, 5), [1, 0.37853, 0.53435], [qw/l u v/], 'convert white to LUV');

# gray
$val = $space->denormalize( [.53389, 0, .686386111] );
is_tuple( $space->round( $val, [9,9,7]), [53.389, 0, 247.099], [qw/luminance chroma hue/], 'denormalize gray');
$val = $space->normalize( [53.389, 0, 247.099] );
is_tuple( $space->round( $val, [9,9,5]), [.53389, 0, .68639], [qw/luminance chroma hue/], 'normalize gray');
$lch = $space->convert_from( 'LUV', [ .53389, .378531073, .534351145] );
is_tuple( $space->round( $lch, 5), [.53389, 0, 0], [qw/luminance chroma hue/], 'convert gray from LUV');
$luv = $space->convert_to( 'LUV', [ .53389, 0, 0.686386111 ] );
is_tuple( $space->round( $luv, 5), [.53389, 0.37853, 0.53435], [qw/l u v/], 'convert gray to LUV');

# red
$val = $space->denormalize( [.53389, 0.685980843, .033816667] );
is_tuple( $space->round( $val, 5), [53.389, 179.041, 12.174], [qw/luminance chroma hue/], 'denormalize red');
$val = $space->normalize( [53.389, 179.041, 12.174] );
is_tuple( $space->round( $val, 5), [.53389, .68598, .03382], [qw/luminance chroma hue/], 'normalize red');
$lch = $space->convert_from( 'LUV', [ .53389, .872923729, .678458015] );
is_tuple( $space->round( $lch, 5), [.53389, .68598, .03382], [qw/luminance chroma hue/], 'convert red from LUV');
$luv = $space->convert_to( 'LUV', [ .53389, 0.685980843, .033816667 ] );
is_tuple( $space->round( $luv, 5), [.53389, 0.87292, 0.67846], [qw/l u v/], 'convert red to LUV');

# blue
$val = $space->denormalize( [.32297, 0.500693487, .738536111] );
is_tuple( $space->round( $val, 5), [32.297, 130.681, 265.873], [qw/luminance chroma hue/], 'denormalize blue');
$val = $space->normalize( [32.297, 130.681, 265.873] );
is_tuple( $space->round( $val, 5), [.32297, .50069, .73854], [qw/luminance chroma hue/], 'normalize blue');
$lch = $space->convert_from( 'LUV', [ .32297, .351963277, .036862595]);
is_tuple( $space->round( $lch, 5), [.32297, .50069, .73854], [qw/luminance chroma hue/], 'convert blue from LUV');
$luv = $space->convert_to( 'LUV', [ .32297, 0.500693487, .738536111 ]);
is_tuple( $space->round( $luv, 5), [.32297, 0.35196, 0.03686], [qw/l u v/], 'convert blue to LUV');

# mid blue
$val = $space->denormalize( [.24082, 0.220954023, .724533333] );
is_tuple( $space->round( $val, 5), [24.082, 57.669, 260.832], [qw/luminance chroma hue/], 'denormalize mid blue');
$val = $space->normalize( [24.082, 57.669, 260.832] );
is_tuple( $space->round( $val, 5), [.24082, .22095, .72453], [qw/luminance chroma hue/], 'normalize mid blue');
$lch = $space->convert_from( 'LUV', [ .24082, .352573446, .317049618] );
is_tuple( $space->round( $lch, 5), [.24082, .22096, .72453], [qw/luminance chroma hue/], 'convert mid blue from LUV');
$luv = $space->convert_to( 'LUV', [ 0.24082, 0.220957034629279, 0.724531985277748 ] );
is_tuple( $space->round( $luv, 5), [.24082, 0.35257, 0.31705], [qw/l u v/], 'convert blue to LUV');

exit 0;


