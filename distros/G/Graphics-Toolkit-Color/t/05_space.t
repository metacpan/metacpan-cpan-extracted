#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 156;
BEGIN { unshift @INC, 'lib', '../lib'}

#### basic object construction #########################################
my $module = 'Graphics::Toolkit::Color::Space';
eval "use $module";
is( not($@), 1, 'could load the module');

my $fspace = Graphics::Toolkit::Color::Space->new();
is( ref $fspace,         '', 'need axis names to create color space');

my $space = Graphics::Toolkit::Color::Space->new(axis => [qw/AAA BBB CCC DDD/]);
is( ref $space,     $module, 'created color space just with axis names');
is( $space->name,    'ABCD', 'got space name from AXIS short names');
is( $space->alias,       '', 'space name alias is empty');
is( $space->axis_count,   4, 'counted axis right');

#### invalid args ######################################################
is( $space->is_value_tuple([1,2,3,4]),   1, 'correct value tuple');
is( $space->is_value_tuple([1,2,3,4,5]), 0, 'too long value tuple');
is( $space->is_value_tuple([1,2,3,]),    0, 'too short value tuple');
is( $space->is_value_tuple({1=>1,2=>2,3=>3,4=>4,}),  0, 'wrong ref type for value tuple');
is( $space->is_value_tuple(''),                      0, 'none ref type can not be value tuple');
is( $space->is_partial_hash(''),                     0, 'need a hash ref to be a partial hash');
is( $space->is_partial_hash({}),                     0, 'a partial hash needs to have at least one key');
is( $space->is_partial_hash({eta =>1}),              0, 'wrong key for partial hash');
is( $space->is_partial_hash({aaa =>1}),              1, 'right key for partial hash');
is( $space->is_partial_hash({aaa =>1,bbb=> 2}),      1, 'two right keys for partial hash');
is( $space->is_partial_hash({aaa =>1,bbb=> 2, ccc=>3}),     1, 'three right keys for partial hash');
is( $space->is_partial_hash({aaa =>1,bbb=> 2, ccc=>3, ddd => 4}), 1, 'four right keys for partial hash');
is( $space->is_partial_hash({aaa =>1,bbb=> 2, ccc=>3, d => 4}), 1, 'can mix full names and shortcut names');
is( $space->is_partial_hash({aaa =>1,bbb=> 2, ccc=>3, z => 4}), 0, 'one bad key makes partial hash invalid');
is( ref $space->basis,  'Graphics::Toolkit::Color::Space::Basis', 'have a valid space basis sub object');
is( ref $space->shape,  'Graphics::Toolkit::Color::Space::Shape', 'have a valid space shape sub object');
is( ref $space->form,   'Graphics::Toolkit::Color::Space::Format','have a valid format sub object');

#### getter ############################################################
$space = Graphics::Toolkit::Color::Space->new(axis => [qw/AAA BBB CCC DDD/], name => 'name');
is( ref $space,     $module, 'created color space just with axis names and space name');
is( $space->name,    'NAME', 'got given space name back');
is( $space->alias,       '', 'no space anme alias this time');
is( $space->is_name('name'),    1,  'can ask if given name is right');
is( $space->is_name('abcd'),    0,  'axis initials are not a space name');
is( $space->is_name(''),        0,  'empty string can never be a space name');

is( ref $space->basis,  'Graphics::Toolkit::Color::Space::Basis', 'have a valid space basis sub object');
is( ref $space->shape,  'Graphics::Toolkit::Color::Space::Shape', 'have a valid space shape sub object');
is( ref $space->form,   'Graphics::Toolkit::Color::Space::Format','have a valid format sub object');

$space = Graphics::Toolkit::Color::Space->new(axis => [qw/AAA BBB CCC DDD/], alias => 'alias');
is( $space->name,    'ABCD', 'got auto generated space name');
is( $space->alias,    'ALIAS', 'got user set space name alias');
is( $space->is_name('abcd'),     1,  'axis initials are a space name');
is( $space->is_name('alias'),    1,  'user set alias is name too');
is( ref $space->basis,  'Graphics::Toolkit::Color::Space::Basis', 'have a valid space basis sub object');
is( ref $space->shape,  'Graphics::Toolkit::Color::Space::Shape', 'have a valid space shape sub object');
is( ref $space->form,   'Graphics::Toolkit::Color::Space::Format','have a valid format sub object');

$space = Graphics::Toolkit::Color::Space->new(axis => [qw/AAA BBB CCC DDD/], name => 'Name');
is( $space->name,        'NAME', 'got space name with given prefix and given Name');
is( ref $space->basis,  'Graphics::Toolkit::Color::Space::Basis', 'have a valid space basis sub object');
is( ref $space->shape,  'Graphics::Toolkit::Color::Space::Shape', 'have a valid space shape sub object');
is( ref $space->form,   'Graphics::Toolkit::Color::Space::Format','have a valid format sub object');

is( ref $space->check_value_shape([0,1,0.5,0.001]),       'ARRAY', 'default to normal range');
is( ref $space->check_value_shape([1,1.1,1,1]),                '', 'one value of tuple is out of range');
my $val = $space->clamp([-1,1.1,1]);
is( ref $val,                'ARRAY', 'clamped value tuple is a tuple');
is( int @$val,                     4, 'filled mising value in');
is( $val->[0],                     0, 'clamped up first value');
is( $val->[1],                     1, 'clamped down second value');
is( $val->[2],                     1, 'passed through third value');
is( $val->[3],                     0, 'zero is default value');

$space = Graphics::Toolkit::Color::Space->new(axis => [qw/AAA BBB CCC DDD/], range => [10,20,'normal', [-10,10]],
                                              name => 'name', alias => 'alias' );
is( $space->name,    'NAME', 'got back user set space name');
is( $space->alias,  'ALIAS', 'got back user set space name alias');
is( $space->is_name('name'),    1,  'axis initials are space name');
is( $space->is_name('alias'),   1,  'user set alias is a space name');
is( $space->is_name('abcd'),    0,  'axis initials are not a space name');

#### value shape #######################################################
is( ref $space,     $module, 'created color space with axis names and ranges');
is( ref $space->shape,  'Graphics::Toolkit::Color::Space::Shape', 'have a valid space shape sub object');
is( ref $space->check_value_shape([10,10,1,10]),                  'ARRAY', 'max values are in range');
is( ref $space->check_value_shape([0,0,0,-10]),                   'ARRAY', 'min values are in range');
is( ref $space->check_value_shape([0,0,2,-10]),                        '', 'one value is ou of range');
$val = $space->clamp([-1,20.1,1]);
is( ref $val,                'ARRAY', 'clamped value tuple is a tuple');
is( int @$val,                     4, 'filled mising value in');
is( $val->[0],                     0, 'clamped up first value');
is( $val->[1],                    20, 'clamped down second value');
is( $val->[2],                     1, 'passed through third value');
is( $val->[3],                     0, 'zero is default value');

$val = $space->normalize([5,10,0.5,0]);
is( ref $val,                'ARRAY', 'normalized value tuple is a tuple');
is( int @$val,                     4, 'right amount of values');
is( $val->[0],                   0.5, 'first value correct');
is( $val->[1],                   0.5, 'second value correct');
is( $val->[2],                   0.5, 'third value correct');
is( $val->[3],                   0.5, 'fourth value correct');

$val = $space->denormalize([ 0.5, 0.5, 0.5, 0.5]);
is( ref $val,                'ARRAY', 'denormalized value tuple is a tuple');
is( int @$val,                     4, 'right amount of values');
is( $val->[0],                     5, 'first value correct');
is( $val->[1],                    10, 'second value correct');
is( $val->[2],                   0.5, 'third value correct');
is( $val->[3],                     0, 'fourth value correct');

$val = $space->denormalize_delta([ 0.5, 0.5, 0.5, 0.5]);
is( ref $val,                'ARRAY', 'denormalized range value tuple is a tuple');
is( int @$val,                     4, 'right amount of values');
is( $val->[0],                     5, 'first value correct');
is( $val->[1],                    10, 'second value correct');
is( $val->[2],                   0.5, 'third value correct');
is( $val->[3],                    10, 'fourth value correct - range had none zero min');

$val = $space->delta([ 1, 1, 1, 1], [ 5, 20, 0, -1]);
is( ref $val,                'ARRAY', 'delta between value tuples is a tuple');
is( int @$val,                     4, 'right amount of values');
is( $val->[0],                     4, 'first value correct');
is( $val->[1],                    19, 'second value correct');
is( $val->[2],                    -1, 'third value correct');
is( $val->[3],                    -2, 'fourth value correct - range had none zero min');

$space = Graphics::Toolkit::Color::Space->new(
   axis => [qw/AAA BBB CCC DDD/], range => 10, precision => [0,1,2,-1],
);
is( ref $space,     $module, 'created color space with axis names, ranges and precision');
is( ref $space->shape,  'Graphics::Toolkit::Color::Space::Shape', 'have a valid space shape sub object');
$val = $space->round([ 1.11111, 1.11111, 1.11111, 1.11111]);
is( ref $val,                'ARRAY', 'rounded value tuple is a tuple');
is( int @$val,                     4, 'right amount of values');
is( $val->[0],                     1, 'first value correct');
is( $val->[1],                   1.1, 'second value correct');
is( $val->[2],                  1.11, 'third value correct');
is( $val->[3],               1.11111, 'fourth value correct - range had none zero min');

$val = $space->clamp([ -0.1111, 1.1111, 200, 0.1111]);
is( ref $val,                'ARRAY', 'clamped value tuple into a tuple');
is( int @$val,                     4, 'right amount of values');
is( $val->[0],                     0, 'clamped up to min');
is( $val->[1],                1.1111, 'second value correct');
is( $val->[2],                    10, 'third value correct');
is( $val->[3],                0.1111, 'fourth value correct');

#### format ############################################################
is( $space->has_format('bbb'), 0, 'vector name is not a format');
is( $space->has_format('c'),   0, 'vector sigil is not  a format');
is( $space->has_format('list'),1, 'list is a format');
is( $space->has_format('hash'),1, 'hash is a format');
is( $space->has_format('char_hash'),1, 'char_hash is a format');
is( ref $space->format([1,2,3,4], 'hash'), 'HASH', 'formatted values into a hash');
is( int($space->format([1,2,3,4], 'list')),     4, 'got long enough list of values');
is( $space->format([1,2,3,4], 'bbb'),          '', 'got no value by key name');
is( $space->format([1,2,3,4], 'AAA'),          '', 'got no value by uc key name');
is( $space->format([1,2,3,4], 'c'),            '', 'got no value by shortcut name');
is( $space->format([1,2,3,4], 'D'),            '', 'got no value by uc shortcut name');
is( $space->has_format('str'),                  0, 'formatter not yet inserted');

my $c = $space->add_formatter('str', sub { $_[1][0] .':'. $_[1][1] .':'. $_[1][2] .':'. $_[1][3]});
is( ref $c,                               'CODE', 'formatter code accepted');
is( $space->has_format('str'),                 1, 'formatter inserted');
my $str = $space->format([1,2,3,4], 'str');
is( $str,                                 '1:2:3:4', 'inserted formatter works');

my $fval = $space->deformat({a => 1, b => 2, c => 3, d => 4});
is( int @$fval,    4, 'deformatter recognized char hash');
is( $fval->[0],    1, 'first value correctly deformatted');
is( $fval->[1],    2, 'second value correctly deformatted');
is( $fval->[2],    3, 'third value correctly deformatted');
is( $fval->[3],    4, 'fourth value correctly deformatted');

$fval = $space->deformat({aaa => 1, bbb => 2, ccc => 3, ddd => 4});
is( int @$fval,   4, 'deformatter recognized hash');
is( $fval->[0],    1, 'first value correctly deformatted');
is( $fval->[1],    2, 'second value correctly deformatted');
is( $fval->[2],    3, 'third value correctly deformatted');
is( $fval->[3],    4, 'fourth value correctly deformatted');

$fval = $space->deformat({a => 1, b => 2, c => 3, e => 4});
is( $fval,  undef, 'char hash with bad key got ignored');
$fval = $space->deformat({aaa => 1, bbb => 2, ccc => 3, dd => 4});
is( $fval,  undef, 'char hash with bad key got ignored');

is( $space->has_deformat('str'),                0, 'deformatter not yet inserted');
my $dc = $space->add_deformatter('str', sub { [split ':', $_[1]] });
is( ref $dc, 'CODE', 'deformatter code accepted');
is( $space->has_deformat('str'),                1, 'deformatter accessible');
$fval = $space->deformat('1:2:3:4');
is( int @$fval,  4, 'self made deformatter recognized str');
is( $fval->[0],  1, 'first value correctly deformatted');
is( $fval->[1],  2, 'second value correctly deformatted');
is( $fval->[2],  3, 'third value correctly deformatted');
is( $fval->[3],  4, 'fourth value correctly deformatted');

#### convert ###########################################################
my @converter = $space->converter_names;
is( $space->can_convert('RGB'),   0, 'converter not yet inserted');
is( int @converter,               0, 'no converter names known');
my $h = $space->add_converter('RGB', sub { $_[0][0]+.1, $_[0][1]-.1, $_[0][2]+.1, $_[0][3]-.1},
                                     sub { $_[0][0]-.1, $_[0][1]+.1, $_[0][2]-.1, $_[0][3]+.1} );
is( ref $h, 'HASH', 'converter code accepted');
is( $space->can_convert('RGB'),   1, 'converter inserted');
@converter = $space->converter_names;
is( int @converter,               1, 'one converter name is known');
is( $converter[0],            'RGB', 'correct converter name is known');

$val = $space->convert_to( 'RGB', [0,0.1,0.2,0.3]);
is( int @$val,      4, 'could convert to RGB');
is( $val->[0],    0.1, 'first value correctly converted');
is( $val->[1],      0, 'second value correctly converted');
is( $val->[2],    0.3, 'third value correctly converted');
is( $val->[3],    0.2, 'fourth value correctly converted');
$val = $space->convert_from('rgb', [0.1, 0, 0.3, .2]);
is( int @$val,    4, 'could deconvert from RGB, even if space spelled in lower case');
is( $val->[0],    0, 'first value correctly deconverted');
is( $val->[1],  0.1, 'second value correctly deconverted');
is( $val->[2],  0.2, 'third value correctly deconverted');
is( $val->[3],  0.3, 'fourth value correctly deconverted');

exit 0;
