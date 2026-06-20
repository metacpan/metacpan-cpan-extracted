#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 147;

my $module = 'Graphics::Toolkit::Color::Space::Shape';
eval "use $module";
is( not($@), 1, 'could load the module');
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
my $constraint = {checker => '$_[0][0]+$_[0][1] <= 1',remedy => '[$_[0][0], 1-$_[0][0], $_[0][2]]', error => 'no'};
my $constraints = {only => $constraint};
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, undef, '%'), '', 'constraints def has to be a hash');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, undef, {}), '', 'empty constraints def is not acceptable');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, undef, {t => {checker => '$_[0]'}}), '', 'only checker is not enough');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, undef, {t => {checker => '$_[0]',remedy => '$_[0]'}}), '', 'only checker and remedy is not enough');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, undef, {t => {checker => '$_[0]',remedy => '$_[0]', error => 'no'}}), $module, 'minimal but correct constraint def');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, undef, {t => $constraint,  tt =>  $constraint}), $module, 'two constraint def');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, undef, {t => {checker => [],remedy => sub{}, error => []}}), '', 'constraint checker is not CODE ref');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, undef, {t => {checker => sub{},remedy => {}, error => []}}), '', 'constraint remedy is not CODE ref');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, undef, undef, {t => {checker => sub{},remedy => sub{}, error => []}}), '', 'error message in constraints def is not a string');

#### arg eval + getter #################################################
$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, ['angular','linear','no']);
is( ref $shape,  $module, 'created shape with all axis types');
is( $shape->is_euclidean,       0, 'space is not euclidean');
is( $shape->is_cylindrical,     0, 'space is not cylindrical');
is( $shape->is_int_valued,      0, 'per default space have full precision');
is( $shape->has_constraints,    0, 'no constraints where given to this space');
is( $shape->is_axis_numeric(0), 1, 'first dimension is numeric');
is( $shape->is_axis_numeric(1), 1, 'second dimension is numeric');
is( $shape->is_axis_numeric(2), 0, 'third dimension is not numeric');
is( $shape->is_axis_numeric(3), 0, 'there is no fourth dimension ');
$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, ['linear','angular','linear']);
is( $shape->is_cylindrical,     1, 'this space is cylindrical');
is( $shape->is_axis_euclidean(0), 1, 'first axis is euclidan');
is( $shape->is_axis_euclidean(1), 0, 'second axis is not euclidan');
is( $shape->is_axis_euclidean(2), 1, 'third axis is euclidan');
is( $shape->is_axis_euclidean(3), 0, 'none existing axis can not be euclidan');
is( $shape->is_axis_angular(0), 0, 'first axis is not angular');
is( $shape->is_axis_angular(1), 1, 'second axis is angular');
is( $shape->is_axis_angular(2), 0, 'third axis is not angular');
is( $shape->is_axis_angular(3), 0, 'none existing axis can not be angular');


$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[0,1],[-1,1],[1,10]]);
is( ref $shape,           $module, 'created shape with most complex range definition');
is( $shape->is_euclidean,       1, 'per default spaces are euclidean');
is( $shape->is_cylindrical,     0, 'per default spaces are not cylindrical');
is( $shape->is_int_valued,      0, 'per default space have full precision');
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
is_tuple( $values, [0, 1, 10], [qw/first second third/], 'clamp tuple with too many values');
$values = $shape->clamp([-.1,1.1] );
is_tuple( $values, [0, 1, 1], [qw/first second third/], 'clamp out of range euclidean axis values');

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
is( $oshape->is_in_bounds(       [0,10,3.111]), 1, "values are in bounds");
is( $oshape->is_in_linear_bounds([-0.1,0,10]),  0, "first value too small");
is( $oshape->is_in_linear_bounds([0,10.1,10]),  0, "second value too large");
is( $oshape->is_in_linear_bounds([10,0,-100]),  0, "third value way too large");
is( $bshape->is_in_linear_bounds([-6,6,1]),     1, "angular dimension can be out out bounds");
is( $bshape->is_in_bounds([-6,6,1]),            0, "angular dimension has to be in bounds now too");
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
is_tuple( $d, [-1, 2, -2.9], [qw/first second third/], 'delta vector under custom range');
$d = $bshape->delta([0.1,0.9, .2], [0.9, 0.1, 0.8] );
is_tuple( $d, [-0.2, .2, -0.4], [qw/first second third/], 'circular delta vector result has right length');

#### clamp & round #####################################################
my $tr = $shape->clamp([-1.1, 0, 20.1, 21, 1] );
is_tuple( $tr, [-1.1, 0, 5], [qw/first second third/], 'clamp into custom range of -5 .. 5');
my $r = $shape->round([-1.0001, -0.009, 20.1], 0);
is_tuple( $r, [-1, 0, 20], [qw/first second third/], 'round with user set precision of 0');

$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, [ 'circular', 'linear', 'linear'], [[-5,5],[-4,4],[-5,5]], [0,1,2] );
$tr = $shape->clamp( [-10, 20] );
is_tuple( $tr, [0, 4, 0], [qw/first second third/], 'clamp into custom range that is defined per axis by space');
$tr = $shape->clamp( [6, -1, 11], [5,7,[-5, 10]]  );
is_tuple( $tr, [1, 0, 10], [qw/first second third/], 'clamp into custom range that is defined per axis and brought as arg');
$r = $shape->round([-1.0001, -0.2109, 20.333]);
is_tuple( $r, [-1, -0.2, 20.33], [qw/first second third/], 'round to space set precision of 2');
$r = $shape->round([-1.0001, -0.2109, 20.333], [0,1,2]);
is_tuple( $r, [-1, -0.2, 20.33], [qw/first second third/], 'round to arg set precision, that is different per axis');
$r = $shape->rotate([-10, 20, 30]);
is_tuple( $r, [0, 20, 30], [qw/first second third/], 'just rotate first value');

$bshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, ['angular', 'circular', 0], [[-5,5],[-5,5],[-5,5]], [0,1,-1],  $constraints);
is( $bshape->has_constraints,            1, 'got some contraints');
is( $bshape->is_in_constraints([0,0,0]), 1, 'origin is within constraints');
is( $bshape->is_in_constraints([1,1,0]), 0, 'point out of constraints');
$tr = $bshape->clamp( [-.1, 3.123, 2.54], ['normal',2,[-1,4]]);
is( $bshape->is_int_valued, 0, 'first axis is not int valued');
is_tuple( $tr, [ .9, .2, 2.54], [qw/first second third/], 'constraints clamped middle value to 0.1, but due to range 0..2 its 0.2');

#### normalize #########################################################
my $norm = $shape->normalize([-5, 0, 5]);
is_tuple( $norm, [ 0, .5, 1], [qw/first second third/], 'normalized extreme  values to range of -5 .. 5');
$norm = $shape->denormalize([0, 0.5 , 1]);
is_tuple( $norm, [ -5, 0, 5], [qw/first second third/], 'denormalized extreme values to range of -5 .. 5');

$norm = $bshape->normalize([-1, 0, 1]);
is_tuple( $norm, [ 0.4, .5, .6], [qw/first second third/], 'normalized values to range of -5 .. 5');
$norm = $bshape->denormalize([0.4, 0.5, .6]);
is_tuple( $norm, [ -1, 0, 1], [qw/first second third/], 'denormalized values to range of -5 .. 5');

$norm = $bshape->denormalize([1, 0, 0.5], [[-10,250],[30,50], [-70,70]]);
is_tuple( $norm, [ 250, 30, 0], [qw/first second third/], 'denormalized tuple on custom range per axis as arg');
$norm = $bshape->normalize([250, 30, 0], [[-10,250],[30,50], [-70,70]]);
is_tuple( $norm, [ 1, 0, 0.5], [qw/first second third/], 'normalized tuple on custom range per axis as arg');

$norm = $shape->denormalize_delta([0, 0.4 , 1]);
is_tuple( $norm, [ 0, 3.2, 10], [qw/first second third/], 'denormalized delta tuple, middle axis is on -4 .. 4');

exit 0;
