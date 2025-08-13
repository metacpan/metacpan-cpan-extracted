#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 178;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Shape';

use_ok( $module, 'could load the module');
my $obj = Graphics::Toolkit::Color::Space::Shape->new();
is( $obj,  undef,       'constructor needs arguments');

my $basis = Graphics::Toolkit::Color::Space::Basis->new( [qw/AAA BBB CCC/] );
my $shape = Graphics::Toolkit::Color::Space::Shape->new( $basis);
is( ref $shape,  $module, 'created shape with default settings');
my $values;

#### invalid args ######################################################
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, {}), qr/invalid axis type/, 'type definition needs to be an ARRAY');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, []), qr/invalid axis type/, 'type definition needs to have same length');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, ['yes','no','maybe']), qr/invalid axis type/, 'undefined values');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, [1,2,3]), qr/invalid axis type/, 'undefined numeric values');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, ['linear','circular','no']), $module, 'valid type def');

is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, {}), '', 'range definition needs to be an ARRAY');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, 1), $module, 'uniform scalar range');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, 'normal'), $module, 'normal scalar range');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, 'percent'), $module, 'percent scalar range');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, []), '', 'range definition ARRAY has to have same lngth');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [1,2,3]), $module, 'ARRAY range with right amount of ints');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1,2],[1,2]]), $module, 'full ARRAY range');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1.1,1.2],[1,2]]), $module, 'full ARRAY range with decimals');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1,2]]), '', 'not enough elements in range def');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1,2],[1,2],[1,2]]), '', 'too many elements in range def');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[2,1],[1,2]]), '', 'one range def element is backward');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1],[1,2]]), '', 'one range def element is too small');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1,2,3],[1,2]]), '', 'one range def element is too big');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1,'-'],[1,2]]), '', 'one range def element has a none number');

is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, 0), $module, 'accepting third constructor arg - precision zero');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, 2), $module, 'precision 2');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, -1), $module, 'precision -1');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, [0,1,-1]), $module, 'full precision def');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, [1,2]), '', 'precision def too short');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, [1,2,3,-1]), '', 'precision def too long');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, undef, '%'), $module, 'accepting fourth constructor arg - a suffix for axis numbers');


#### arg eval + getter #################################################
$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, ['angular','linear','no']);
is( ref $shape,  $module, 'created shape with all axis types');
is( $shape->is_axis_numeric(0), 1, 'first dimension is numeric');
is( $shape->is_axis_numeric(1), 1, 'second dimension is numeric');
is( $shape->is_axis_numeric(2), 0, 'third dimension is not numeric');
is( $shape->is_axis_numeric(3), 0, 'there is no fourth dimension ');

$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[0,1],[-1,1],[1,10]]);
is( ref $shape,  $module, 'created shape with most complex range definition');
is( $shape->is_axis_numeric(0), 1, 'default to numeric axis on first dimension');
is( $shape->is_axis_numeric(1), 1, 'default to numeric axis on second dimension');
is( $shape->is_axis_numeric(2), 1, 'default to numeric axis on third dimension');
is( $shape->is_axis_numeric(3), 0, 'there is no fourth dimension');
is( $shape->axis_value_max(0),  1, 'max value of first dimension');
is( $shape->axis_value_max(1),  1, 'max value of second dimension');
is( $shape->axis_value_max(2), 10, 'max value of third dimension');
is( $shape->axis_value_max(3), undef, 'get undef when asking for max of none existing dimension');
is( $shape->axis_value_min(0),  0, 'min value of first dimension');
is( $shape->axis_value_min(1), -1, 'min value of second dimension');
is( $shape->axis_value_min(2),  1, 'min value of third dimension');
is( $shape->axis_value_min(3), undef, 'get undef when asking for min of none existing dimension');

$values = $shape->clamp([0, 1, 10, 1] );
is( ref $values, 'ARRAY', 'clamped in bound values after complex range def');
is( int @$values,      3, 'clamp down to correct tuple length = 3');
is( $values->[0],      0, 'value that touched on lower bound was not altered');
is( $values->[1],      1, 'value that touched on upper bound was not altered');
is( $values->[2],     10, 'value in middle of range was not altered');
$values = $shape->clamp([-.1,1.1] );
is( ref $values, 'ARRAY', 'clamp out of bounds values after complex range def');
is( int @$values,      3, 'filled to correct tuple length = 3');
is( $values->[0],      0, 'value below lower bound was clamped up');
is( $values->[1],      1, 'value above upper bound was clamped down');
is( $values->[2],      1, 'filled in missing value with lower bounds, since 0 is out of range');

$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, [-1,0,1]);
is( ref $shape,  $module, 'created shape with complex precision definition');
is( $shape->axis_value_precision(0), -1, 'first dimension precision');
is( $shape->axis_value_precision(1), 0, 'second dimension precision');
is( $shape->axis_value_precision(2), 1, 'third dimension precision');
$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, ['angular','linear','no'], undef, [-1,0,1]);
is( $shape->axis_value_precision(2), undef, 'third dimension precision does not count (not numeric)');

my $bshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, ['angular', 'circular', 0], [[-5,5],[0,5],[-5,0]], );
is( ref $bshape,  $module, 'created 3D bowl shape with -5..5 range');
is( $bshape->axis_value_precision(0), -1, 'first dimension is int on default');
is( $bshape->axis_value_precision(1), -1, 'second dimension is int on default');
is( $bshape->axis_value_precision(2), -1, 'third dimension is int on default');

my $nshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, 'normal');
is( $nshape->axis_value_precision(0) < 0, 1, 'first normal dimension is real because normal');
is( $nshape->axis_value_precision(1) < 0, 1, 'second normal dimension is real because normal');
is( $nshape->axis_value_precision(2) < 0, 1, 'third normal dimension is real because normal');

my $mshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, ['normal', 100, 2], 2);
is( $mshape->axis_value_precision(0), 2, 'expanded compact precision to first axis');
is( $mshape->axis_value_precision(1), 2, 'expanded compact precision to second axis');
is( $mshape->axis_value_precision(2), 2, 'expanded compact precision to third axis');

my $oshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[0, 10], [0, 10], [0, 10]], [2, 0, -1]);
is( ref $oshape,  $module, 'space shape with 0..10 axis and hand set precision');
is( $oshape->axis_value_precision(0), 2, 'first dimension has set precision');
is( $oshape->axis_value_precision(1), 0, 'second dimension has set precision');
is( $oshape->axis_value_precision(2), -1,'third dimension has set precision');

#### check value shape #################################################
is( ref $oshape->check_value_shape(1,2,3),        '',  'need array ref, not list');
is( ref $oshape->check_value_shape({}),           '',  'need array, not other ref');
is( ref $oshape->check_value_shape([1,2,3]), 'ARRAY',  'all values in range');
is( ref $oshape->check_value_shape([1,2]),        '',  "not enough values");
is( ref $oshape->check_value_shape([1,2,3,4]),    '',  "too many values");
is( ref $oshape->check_value_shape([1,22,3]),     '',  "too big second value");
is( ref $oshape->check_value_shape([1,22,-1]),    '',  "too small third value");
is( ref $oshape->check_value_shape([0,1.111,3.111]),'',"too many decimals in second value");

#### is_in_linear_bounds ###############################################
is( $oshape->is_in_linear_bounds({}),           0, "bad format");
is( $oshape->is_in_linear_bounds([1,2]),        0, "not enough values");
is( $oshape->is_in_linear_bounds([1,2,3,4]),    0, "too many values");
is( $oshape->is_in_linear_bounds([0,10,3.111]), 1, "normal in range values");
is( $oshape->is_in_linear_bounds([-0.1,0,10]),  0, "first value too small");
is( $oshape->is_in_linear_bounds([0,10.1,10]),  0, "second value too large");
is( $oshape->is_in_linear_bounds([10,0,-100]),  0, "third value way too large");
is( $bshape->is_in_linear_bounds([-6,6,1]),     1, "angular dimension can be out out bounds");
is(  $shape->is_in_linear_bounds([2,1,2]),      1, "only linear dimension is in bound");
is(  $shape->is_in_linear_bounds([2,2,2]),      0, "now linear dimension is out of bound");

#### is_equal ##########################################################
is( $shape->is_equal(),                                         0, 'is_equal needs arguments');
is( $shape->is_equal(               3,     [1,2,3]           ), 0, 'first tuple has wrong ref');
is( $shape->is_equal(       [1,2,3,4],     [1,2,3]           ), 0, 'first tuple is out of shape');
is( $shape->is_equal(         [1,2,3],          {}           ), 0, 'second tuple has the wrong ref');
is( $shape->is_equal(         [1,2,3],       [1,2]           ), 0, 'second tuple is out of shape');
is( $shape->is_equal(         [1,2,3],     [1,2,3]           ), 1, 'values are equal');
is( $shape->is_equal( [1.111,2,2.999], [1.112,2,3],         2), 1, 'precision definition is held up');
is( $shape->is_equal([1.111,2.13,2.9], [1.112,2.14,3],[2,1,0]), 1, 'complex precision definition is held up');

#### delta #############################################################
my $d = $bshape->delta(1, [1,5,4,5] );
is( ref $d,  '', 'reject compute delta on none vector on first arg position');
$d = $shape->delta([1,5,4,5], 1 );
is( ref $d,  '', 'reject compute delta on none vector on second arg position');
$d = $shape->delta([2,3,4,5], [1,5,4] );
is( ref $d,  '', 'reject compute delta on too long first vector');
$d = $shape->delta([2,3], [1,5,1] );
is( ref $d,  '', 'reject compute delta on too short first  vector');
$d = $shape->delta([2,3,4], [5,1,4,5] );
is( ref $d,  '', 'reject compute delta on too long second vector');
$d = $shape->delta([2,3,4], [5,1] );
is( ref $d,  '', 'reject compute delta on too short second  vector');

$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[-5,5]]);
$d = $shape->delta([2,3,4], [1,5,1.1] );
is( ref $d,   'ARRAY', 'copied 2 bounded axis range def to other axis');
is( int @$d,        3, 'linear delta result has right length');
is( $d->[0],       -1, 'first delta value correct');
is( $d->[1],        2, 'second delta value correct');
is( $d->[2],     -2.9, 'third delta value correct');

$d = $bshape->delta([0.1,0.9, .2], [0.9, 0.1, 0.8] );
is( int @$d,   3, 'circular delta result has right length');
is( $d->[0],   -0.2, 'first delta value correct');
is( $d->[1],     .2, 'second delta value correct');
is( $d->[2],   -0.4, 'third delta value correct');

#### clamp & round #####################################################
my $tr = $shape->clamp([-1.1, 0, 20.1, 21, 1] );
is( ref $tr, 'ARRAY', 'got back a value ARRAY (vector) from clamp');
is( int @$tr,   3, 'clamp down to correct vector length = 3');
is( $tr->[0],  -1.1, 'clamp does not touch small negative value');
is( $tr->[1],   0, 'do not touch minimal value');
is( $tr->[2],   5, 'clamp too large nr into upper bound');

my $r = $shape->round([-1.0001, -0.009, 20.1], 0);
is( ref $r,'ARRAY', 'got back a value ARRAY (tuple) from round');
is( int @$r,     3, 'rounded three values');
is( $r->[0],    -1, 'rounded negative value');
is( $r->[1],     0, 'rounded zero');
is( $r->[2],    20, 'rounded too large value');

$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, [ 'circular', 'linear', 'linear'], [[-5,5],[-5,5],[-5,5]], [0,1,2] );
$tr = $shape->clamp( [-10, 20] );
is( int @$tr,  3, 'clamp added missing value');
is( $tr->[0],  0, 'rotates in circular value');
is( $tr->[1],  5, 'value was just max, clamped to min');
is( $tr->[2],  0, 'added a zero into missing value');

$tr = $shape->clamp( [6, -1, 11], [5,7,[-5, 10]]  );
is( int @$tr,   3, 'clamp with special range def');
is( $tr->[0],    1, 'rotated larg value down');
is( $tr->[1],    0, 'too small value clamped up to min');
is( $tr->[2],   10, 'clamped down into special range');

$r = $shape->round([-1.0001, -0.2109, 20.333]);
is( ref $r,'ARRAY', 'rounding with custom precision, different for each axis');
is( int @$r,     3, 'rounded three values');
is( $r->[0],    -1, 'rounded to int');
is( $r->[1],  -0.2, 'rounded with precision 1');
is( $r->[2], 20.33, 'rounded with precision 2');

$r = $shape->round([-1.0001, -0.2109, 20.333], [0,1,2]);
is( ref $r,'ARRAY', 'rounding with insert precision different for each axis');
is( int @$r,     3, 'rounded three values');
is( $r->[0],    -1, 'rounded to int');
is( $r->[1],  -0.2, 'rounded with precision 1');
is( $r->[2], 20.33, 'rounded with precision 2');

$bshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, ['angular', 'circular', 0], [[-5,5],[-5,5],[-5,5]], [0,1,-1]);
$tr = $bshape->clamp( [-.1, 1.123, 2.54], ['normal',2,[-1,4]]);
is( int @$tr,    3, 'clamp kept right amount of values');
is( $tr->[0],  0.9, 'rotated value to int');
is( $tr->[1],  1.123, 'left second value untouched');
is( $tr->[2], 2.54, 'in range value is kept');

#### normalize #########################################################
my $norm = $shape->normalize([-5, 0, 5]);
is( ref $norm,   'ARRAY', 'normalized values');
is( int @$norm,   3, 'normalized 3 into 3 values');
is( $norm->[0],    0, 'normalized first min value');
is( $norm->[1],    0.5, 'normalized second mid value');
is( $norm->[2],    1,   'normalized third max value');

$norm = $shape->denormalize([0, 0.5 , 1]);
is( @$norm,        3, 'denormalized 3 into 3 values');
is( $norm->[0],   -5, 'denormalized min value');
is( $norm->[1],    0, 'denormalized second mid value');
is( $norm->[2],    5, 'denormalized third max value');

$norm = $bshape->normalize([-1, 0, 5]);
is( @$norm,   3, 'normalize bawl coordinates');
is( $norm->[0],    0.4, 'normalized first min value');
is( $norm->[1],    0.5, 'normalized second mid value');
is( $norm->[2],    1,   'normalized third max value');

$norm = $bshape->denormalize([0.4, 0.5, 1]);
is( @$norm,   3, 'denormalized 3 into 3 values');
is( $norm->[0],   -1, 'denormalized small value');
is( $norm->[1],    0, 'denormalized mid value');
is( $norm->[2],    5, 'denormalized max value');

$norm = $bshape->denormalize([1, 0, 0.5], [[-10,250],[30,50], [-70,70]]);
is( @$norm,   3, 'denormalized bowl with custom range');
is( $norm->[0],  250, 'denormalized with special ranges max value');
is( $norm->[1],   30, 'denormalized with special ranges min value');
is( $norm->[2],    0, 'denormalized with special ranges mid value');

$norm = $bshape->normalize([250, 30, 0], [[-10,250],[30,50], [-70,70]]);
is( @$norm,  3,  'normalized  bowl with custom range');
is( $norm->[0],   1,  'normalized with special ranges max value');
is( $norm->[1],   0,  'normalized with special ranges min value');
is( $norm->[2],   0.5,'normalized with special ranges mid value');

$norm = $shape->denormalize_delta([0, 0.5 , 1]);
is( @$norm,        3, 'denormalized 3 into 3 values');
is( $norm->[0],    0, 'denormalized min delta');
is( $norm->[1],    5, 'denormalized second mid delta');
is( $norm->[2],   10, 'denormalized third max delta');

exit 0;

