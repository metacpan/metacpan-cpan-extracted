#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 76;
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELUV';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'LUV', 'color space name is CIELUV');
is( $space->name('alias'),               'CIELUV', 'color space alias is LUV');
is( $space->is_name('cieLUV'),                  1, 'full space  name recognized');
is( $space->is_name('Luv'),                     1, 'axis initials do qual space name');
is( $space->is_name('Lab'),                     0, 'axis initials do not equal space name this time');
is( $space->is_axis_name('luv'),                0, 'space name is not axis name');
is( $space->is_axis_name('L*'),                 1, '"L*" is an axis name');
is( $space->is_axis_name('u*'),                 1, '"u*" is an axis name');
is( $space->is_axis_name('v*'),                 1, '"v" is an axis name');
is( $space->is_axis_name('*'),                  0, 'can not miss a lettter of axis name');
is( $space->is_axis_name('l'),                  1, '"l" is an axis name');
is( $space->is_axis_name('u'),                  1, '"u" is an axis name');
is( $space->is_axis_name('v'),                  1, '"v" is an axis name');
is( $space->pos_from_axis_name('L*'),           0, '"L*" is name of first axis');
is( $space->pos_from_axis_name('u*'),           1, '"u*" is name of second axis');
is( $space->pos_from_axis_name('v*'),           2, '"v*" is name of third axis');
is( $space->pos_from_axis_name('l'),            0, '"l" is name of first axis');
is( $space->pos_from_axis_name('u'),            1, '"u" is name of second axis');
is( $space->pos_from_axis_name('v'),            2, '"v" is name of third axis');
is( $space->pos_from_axis_name('*'),        undef, '"*" is not an axis name');
is( $space->axis_count,                         3, 'CIELUV has 3 dimensions');
is( $space->is_euclidean,                       1, 'CIELUV is euclidean');
is( $space->is_cylindrical,                     0, 'CIELUV is not cylindrical');

is( ref $space->check_value_shape([0, 0, 0]),          'ARRAY', 'check minimal CIELUV values are in bounds');
is( ref $space->check_value_shape([0.950, 1, 1.088]),  'ARRAY', 'check maximal CIELUV values');
is( ref $space->check_value_shape([0,0]),                   '', "CIELUV got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),            '', "CIELUV got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),            '', "L value is too small");
is( ref $space->check_value_shape([100, 0, 0]),        'ARRAY', 'L value is maximal');
is( ref $space->check_value_shape([101, 0, 0]),             '', "L value is too big");
is( ref $space->check_value_shape([0, -134, 0]),       'ARRAY', 'u value is minimal');
is( ref $space->check_value_shape([0, -134.1, 0]),          '', "u value is too small");
is( ref $space->check_value_shape([0, 220, 0]),        'ARRAY', 'u value is maximal');
is( ref $space->check_value_shape([0, 220.1, 0]),           '', "u value is too big");
is( ref $space->check_value_shape([0, 0, -140]),       'ARRAY', 'v value is minimal');
is( ref $space->check_value_shape([0, 0, -140.1 ] ),        '', "v value is too small");
is( ref $space->check_value_shape([0, 0, 122]),        'ARRAY', 'v value is maximal');
is( ref $space->check_value_shape([0, 0, 122.2] ),          '', "v value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({u => 1, v => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({u => 1, v => 0, l => 0}), 1, 'found hash with all axis names');
is( $space->is_partial_hash({'L*' => 1, 'u*' => 0, 'v*' => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({a => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'XYZ'), 1,                 'do only convert from and to rgb');
is( $space->can_convert( 'xyz'), 1,                 'namespace can be written lower case');
is( $space->can_convert( 'CIEluv'), 0,                 'can not convert to itself');
is( $space->can_convert( 'luv'), 0,                    'can not convert to itself (alias)');
is( $space->format([0,0.234,120], 'css_string'), 'luv(0, 0.234, 120)', 'can format css string');

my $val = $space->deformat(['CIELUV', 0, -1, -0.1]);
is_tuple( $val, [0, -1, -0.1], [qw/l u v/], 'deformated named ARRAY into tuple');
is( $space->format([0,1,0], 'css_string'), 'luv(0, 1, 0)', 'can format css string');

# black
$val = $space->denormalize( [0, .378531073, .534351145] );
is_tuple( $space->round( $val, 5), [0, 0, 0], [qw/l u v/], 'denormalized black into zeros');
$val = $space->normalize( [0, 0, 0] );
is_tuple( $space->round( $val, 5), [0, 0.37853, 0.53435], [qw/l u v/], 'normalized tuple of zeros (black)');
my $luv = $space->convert_from( 'XYZ', [ 0, 0, 0]);
is_tuple( $space->round( $luv, 5), [0, 0.37853, 0.53435], [qw/l u v/], 'deconverted tuple of zeros (black) from XYZ');
my $xyz = $space->convert_to( 'XYZ', [ 0, .378531073, .534351145 ]);
is_tuple( $space->round( $xyz, 5), [0, 0, 0], [qw/X Y Z/], 'converted black to XYZ');

# white
$val = $space->denormalize( [1, .378531073, .534351145] );
is_tuple( $space->round( $val, 5), [100, 0, 0], [qw/l u v/], 'denormalized white into zeros');
$val = $space->normalize( [100, 0, 0] );
is_tuple( $space->round( $val, 5), [1, 0.37853, 0.53435], [qw/l u v/], 'normalized tuple of white');
$luv = $space->convert_from( 'XYZ', [ 1, 1, 1]);
is_tuple( $space->round( $luv, 5), [1, 0.37853, 0.53435], [qw/l u v/], 'converted white from XYZ to LUV');
$xyz = $space->convert_to( 'XYZ', [ 1, .378531073, .534351145 ]);
is_tuple( $space->round( $xyz, 5), [1, 1, 1], [qw/X Y Z/], 'converted white to XYZ');

# gray
$val = $space->denormalize( [0.53389, .378531073, .534351145] );
is_tuple( $space->round( $val, 5), [53.389, 0, 0], [qw/l u v/], 'denormalize gray');
$val = $space->normalize( [53.389, 0, 0] );
is_tuple( $space->round( $val, 5), [0.53389, 0.37853, 0.53435], [qw/l u v/], 'normalize gray');
$luv = $space->convert_from( 'XYZ', [ .214041474 , .21404, 0.214037086]);
is_tuple( $space->round( $luv, 5), [0.53389, 0.37853, 0.53435], [qw/l u v/], 'deconverted gray from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 0.53389, .378531073, .534351145 ]);
is_tuple( $space->round( $xyz, 5), [0.21404, 0.21404, 0.21404], [qw/X Y Z/], 'converted gray to XYZ');

# red
$val = $space->denormalize( [0.53241, .872923729, .678458015] );
is_tuple( $space->round( $val, 5), [53.241, 175.015, 37.756], [qw/l u v/], 'denormalize red');
$val = $space->normalize( [53.241, 175.015, 37.756] );
is_tuple( $space->round( $val, 5), [0.53241, 0.87292, 0.67846], [qw/l u v/], 'normalize red');
$luv = $space->convert_from( 'XYZ', [ 0.433953728, 0.21267, 0.017753001]);
is_tuple( $space->round( $luv, [5,4,5]), [0.5324, 0.8729, 0.67846], [qw/l u v/], 'deconverted red from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 0.53241, .872923729, .678458015 ]);
is_tuple( $space->round( $xyz, 5), [0.43395, 0.21267, 0.01776], [qw/X Y Z/], 'converted red to XYZ');

# blue
$luv = $space->denormalize( [0.32297, .351963277, .036862595] );
is_tuple( $space->round( $luv, 5), [32.297, -9.405, -130.342], [qw/l u v/], 'denormalize blue');
$luv = $space->normalize( [32.297, -9.405, -130.342] );
is_tuple( $space->round( $luv, 5), [0.32297, 0.35196, 0.03686], [qw/l u v/], 'normalize blue');
$luv = $space->convert_from( 'XYZ', [ 0.1898429198, 0.07217, 0.872771690713886]);
is_tuple( $space->round( $luv, 5), [0.32296, 0.35197, 0.03687], [qw/l u v/], 'deconverted blue from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 0.322958956314709, 0.351970231199232, 0.0368661363328552 ]);
is_tuple( $space->round( $xyz, 5), [0.18984, 0.07217, 0.87277], [qw/X Y Z/], 'converted blue to XYZ');

# nice blue
$luv = $space->denormalize( [0.24082, .352573446, .317049618] );
is_tuple( $space->round( $luv, 5), [24.082, -9.189, -56.933], [qw/l u v/], 'denormalize nice blue');
$luv = $space->normalize( [24.082, -9.189, -56.933] );
is_tuple( $space->round( $luv, 5), [0.24082, 0.35257, 0.31705], [qw/l u v/], 'normalize nice blue');
$luv = $space->convert_from( 'XYZ', [ 0.057434743, .04125, .190608268]);
is_tuple( $space->round( $luv, 5), [0.2408, 0.35258, 0.31705], [qw/l u v/], 'deconverted nice blue from XYZ');
$xyz = $space->convert_to( 'XYZ', [ 0.240804547340649, 0.352579240249493, 0.317048140883067 ]);
is_tuple( $space->round( $xyz, 5), [0.05743, 0.04125, 0.19061], [qw/X Y Z/], 'converted nice blue to XYZ');

exit 0;



