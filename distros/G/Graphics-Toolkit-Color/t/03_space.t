#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 83;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space';

eval "use $module";
is( not($@), 1, 'could load the module');

my $fspace = Graphics::Toolkit::Color::Space->new();
is( ref $fspace, '', 'need vector names to create color space');
my $space = Graphics::Toolkit::Color::Space->new(qw/AAA BBB CCC DDD/);
is( ref $space, $module, 'could create a space object');
is( $space->name,  'ABCD', 'space has right name');
is( $space->dimensions, 4, 'space has four dimension');
is( $space->has_format('bbb'), 1, 'vector name is a format');
is( $space->has_format('c'),   1, 'vector sigil is a format');
is( $space->has_format('list'),1, 'list is a format');
is( $space->has_format('hash'),1, 'hash is a format');
is( $space->has_format('char_hash'),1, 'char_hash is a format');

is( ref $space->format([1,2,3,4], 'hash'), 'HASH', 'formatted values into a hash');
is( int($space->format([1,2,3,4], 'list')),     4, 'got long enough list of values');

is( $space->format([1,2,3,4], 'bbb'),           2, 'got right value by key name');
is( $space->format([1,2,3,4], 'AAA'),           1, 'got right value by uc key name');
is( $space->format([1,2,3,4], 'c'),             3, 'got right value by shortcut name');
is( $space->format([1,2,3,4], 'D'),             4, 'got right value by uc shortcut name');

is( $space->has_format('str'),   0, 'formatter not yet inserted');
my $c = $space->add_formatter('str', sub { $_[0] . $_[1] . $_[2] . $_[3]});
is( ref $c, 'CODE', 'formatter code accepted');
is( $space->has_format('str'),   1, 'formatter inserted');
is( $space->format([1,2,3,4], 'str'),     '1234', 'inserted formatter works');

my @fval = $space->deformat({a => 1, b => 2, c => 3, d => 4});
is( int @fval,  4, 'deformatter recognized char hash');
is( $fval[0],    1, 'first value correctly deformatted');
is( $fval[1],    2, 'second value correctly deformatted');
is( $fval[2],    3, 'third value correctly deformatted');
is( $fval[3],    4, 'fourth value correctly deformatted');

@fval = $space->deformat({aaa => 1, bbb => 2, ccc => 3, ddd => 4});
is( int @fval,  4, 'deformatter recognized hash');
is( $fval[0],    1, 'first value correctly deformatted');
is( $fval[1],    2, 'second value correctly deformatted');
is( $fval[2],    3, 'third value correctly deformatted');
is( $fval[3],    4, 'fourth value correctly deformatted');

@fval = $space->deformat({a => 1, b => 2, c => 3, e => 4});
is( $fval[0],  undef, 'char hash with bad key got ignored');
@fval = $space->deformat({aaa => 1, bbb => 2, ccc => 3, dd => 4});
is( $fval[0],  undef, 'char hash with bad key got ignored');

my $dc = $space->add_deformatter('str', sub { split ':', $_[0] });
is( ref $dc, 'CODE', 'deformatter code accepted');
@fval = $space->deformat('1:2:3:4');
is( int @fval,  4, 'self made deformatter recognized str');
is( $fval[0],    1, 'first value correctly deformatted');
is( $fval[1],    2, 'second value correctly deformatted');
is( $fval[2],    3, 'third value correctly deformatted');
is( $fval[3],    4, 'fourth value correctly deformatted');


is( $space->can_convert('XYZ'),   0, 'converter not yet inserted');
my $h = $space->add_converter('XYZ', sub { $_[0]+1, $_[1]+1, $_[2]+1, $_[3]+1},
                                     sub { $_[0]-1, $_[1]-1, $_[2]-1, $_[3]-1} );
is( ref $h, 'HASH', 'converter code accepted');
is( $space->can_convert('XYZ'),   1, 'converter inserted');
my @val = $space->convert([1,2,3,4], 'XYZ');
is( int @val,   4, 'converter did something');
is( $val[0],    2, 'first value correctly converted');
is( $val[1],    3, 'second value correctly converted');
is( $val[2],    4, 'third value correctly converted');
is( $val[3],    5, 'fourth value correctly converted');
@val = $space->deconvert([2,3,4,5], 'xyz');
is( int @val,   4, 'deconverter did something even if space spelled in lower case');
is( $val[0],    1, 'first value correctly deconverted');
is( $val[1],    2, 'second value correctly deconverted');
is( $val[2],    3, 'third value correctly deconverted');
is( $val[3],    4, 'fourth value correctly deconverted');


my @d = $space->delta(1, [1,5,4,5] );
is( int @d,   0, 'reject compute delta on none vector on first arg position');
@d = $space->delta([1,5,4,5], 1 );
is( int @d,   0, 'reject compute delta on none vector on second arg position');
@d = $space->delta([2,3,4,5,1], [1,5,4,5] );
is( int @d,   0, 'reject compute delta on too long first vector');
@d = $space->delta([2,3,4], [1,5,1,1] );
is( int @d,   0, 'reject compute delta on too short first  vector');
@d = $space->delta([2,3,4,5], [1,5,1,4,5] );
is( int @d,   0, 'reject compute delta on too long second vector');
@d = $space->delta([2,3,4,5], [1,5,1] );
is( int @d,   0, 'reject compute delta on too short second  vector');

@d = $space->delta([2,3,4,5], [1,5,1,1] );
is( int @d,   4, 'delta result has right length');
is( $d[0],   -1, 'first value correctly deconverted');
is( $d[1],    2, 'second value correctly deconverted');
is( $d[2],   -3, 'third value correctly deconverted');
is( $d[3],   -4, 'fourth value correctly deconverted');

my $res = $space->change_delta_routine(
    sub {my ($vector1, $vector2) = @_; map {abs($vector1->[$_] + $vector2->[$_]) } $space->iterator}
);
is( ref $res, 'CODE', 'delta sub was changed');
@d = $space->delta([2,3,4,5], [1,5,1,1] );
is( int @d,   4, 'self made delta result has right length');
is( $d[0],    3, 'first value correctly deconverted');
is( $d[1],    8, 'second value correctly deconverted');
is( $d[2],    5, 'third value correctly deconverted');
is( $d[3],    6, 'fourth value correctly deconverted');

my @tr = $space->trim(-1,0,1,2);
is( int @tr,  4, 'trim kept correct vector length');
is( $tr[0],    0, 'trim raised too low value');
is( $tr[1],    0, 'trim kept value on lower edge');
is( $tr[2],    1, 'trim kept value on upper edge');
is( $tr[3],    1, 'trim lowered too small value');

@tr = $space->trim(-1,0,1,2, 5);
is( int @tr,  4, 'trim lowered too largw vector');
@tr = $space->trim(-1,0,1);
is( int @tr,  4, 'trim prolonged too short vector');
is( $tr[3],   0, 'filled missing values with 0 as it should');

my $tres = $space->change_trim_routine( 'CODE' );
is( $tres,  '', 'trim routine changer method only accepts CODE ref');
$tres = $space->change_trim_routine( sub { map { $_ < 0 ? 0 : $_} map {$_ > 10 ? 10 : $_}  @_ });
is( ref $tres, 'CODE', 'trim code was changed');

@tr = $space->trim(-1,0,10,11, 5);
is( int @tr,  4, 'new trim still lowered vector to right size');
is( $tr[0],   0, 'trim raised too low value');
is( $tr[1],   0, 'trim kept value on lower edge');
is( $tr[2],  10, 'trim kept value on upper edge');
is( $tr[3],  10, 'trim lowered too small value');


exit 0;
