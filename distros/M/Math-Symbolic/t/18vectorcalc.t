#!perl
use strict;
use warnings;

use Test::More tests => 19;

BEGIN {
	use_ok('Math::Symbolic');
	use_ok('Math::Symbolic::VectorCalculus');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic qw/:all/;
use Math::Symbolic::ExportConstants qw/:all/;
use Math::Symbolic::VectorCalculus qw/:all/;

my $func = 'x+y';
my @grad = grad 'x+y';
ok(
    (
              @grad == 2
          and $grad[0]->is_identical('partial_derivative(x + y, x)')
          and $grad[1]->is_identical('partial_derivative(x + y, y)')
    ),
    'simple grad usage'
);

$func = parse_from_string('2*x+y+3*z');
@grad = grad $func;
ok(
    (
              @grad == 3
          and $grad[0]->is_identical('partial_derivative(((2*x)+y)+(3*z),x)')
          and $grad[1]->is_identical('partial_derivative(((2*x)+y)+(3*z),y)')
          and $grad[2]->is_identical('partial_derivative(((2*x)+y)+(3*z),z)')
    ),
    'more simple grad usage'
);

@grad = grad $func, @{ [qw/y x/] };
ok(
    (
              @grad == 2
          and $grad[0]->is_identical('partial_derivative(((2*x)+y)+(3*z),y)')
          and $grad[1]->is_identical('partial_derivative(((2*x)+y)+(3*z),x)')
    ),
    'more grad usage with custom signature'
);

my @func1 = ( 'x+y', 'x+z', 'z*y' );
my @func2 = map { parse_from_string($_) } @func1;

my $div = div @func1;
ok( $div->is_identical(<<'HERE'), 'simple divergence usage' );
((partial_derivative(x + y, x)) +
 (partial_derivative(x + z, y))) +
(partial_derivative(z * y, z))
HERE

$div = div @func2;
ok( $div->is_identical(<<'HERE'), 'more simple divergence usage' );
((partial_derivative(x + y, x)) +
 (partial_derivative(x + z, y))) +
(partial_derivative(z * y, z))
HERE

$div = div @func2, @{ [ 'x', 'z', 'y' ] };
ok( $div->is_identical(<<'HERE'), 'divergence usage with custom signature' );
((partial_derivative(x + y, x)) +
 (partial_derivative(x + z, z))   ) +
(partial_derivative(z * y, y))
HERE

my @rot = rot @func1;
ok(
    (
              @rot == 3
          and $rot[0]->is_identical(<<'ROT0')
(partial_derivative(z * y, y)) - (partial_derivative(x + z, z))
ROT0
          and $rot[1]->is_identical(<<'ROT1'),
(partial_derivative(x + y, z)) - (partial_derivative(z * y, x))
ROT1
          and $rot[2]->is_identical(<<'ROT2'),
(partial_derivative(x + z, x)) - (partial_derivative(x + y, y))
ROT2
    ),
    'basic rot usage'
);

my @expected = (
    'partial_derivative(x + y, x)',
    'partial_derivative(x + y, y)',
    'partial_derivative(x + y, z)',
    'partial_derivative(x + z, x)',
    'partial_derivative(x + z, y)',
    'partial_derivative(x + z, z)',
    'partial_derivative(z * y, x)',
    'partial_derivative(z * y, y)',
    'partial_derivative(z * y, z)',
);
my @matrix = Jacobi @func1;
ok(
    (
        @matrix == 3
          and
          ( grep { $_->is_identical( shift @expected ) } map { (@$_) } @matrix )
          == 9
    ),
    'basic Jacobi usage'
);

@expected = (
    'partial_derivative(partial_derivative(x * y, x), x)',
    'partial_derivative(partial_derivative(x * y, x), y)',
    'partial_derivative(partial_derivative(x * y, y), x)',
    'partial_derivative(partial_derivative(x * y, y), y)',
);
@matrix = Hesse 'x*y';
ok(
    (
        @matrix == 2 and not(
            grep { not $_->is_identical( shift @expected ) }
            map  { (@$_) } @matrix
        )
    ),
    'basic Hesse usage'
);

my $differential = TotalDifferential 'x*y';
ok( $differential->is_identical(<<'HERE'), 'basic TotalDifferential usage' );
partial_derivative(x_0*y_0,x_0)*(x-x_0) +
partial_derivative(x_0*y_0,y_0)*(y-y_0)
HERE

$differential = TotalDifferential 'x*y+z', @{ [qw/z x/] };
ok(
    $differential->is_identical(
        <<'HERE'), 'more basic TotalDifferential usage' );
partial_derivative(x_0*y+z_0,z_0)*(z-z_0) +
partial_derivative(x_0*y+z_0,x_0)*(x-x_0)
HERE

$differential = TotalDifferential 'x*y+z', @{ [qw/z x/] }, @{ [qw/z0 x0/] };
ok(
    $differential->is_identical(
        <<'HERE'), 'yet more basic TotalDifferential usage' );
partial_derivative(x0*y+z0,z0)*(z-z0) +
partial_derivative(x0*y+z0,x0)*(x-x0)
HERE

my $foo;
my $line = <DATA>;
eval $line;
die $@ if $@;

my $dderiv = DirectionalDerivative 'x*y+z',
  @{ [ 'a', Math::Symbolic::Variable->new('b'), 'c' ] };
ok( $dderiv->is_identical($foo), 'basic DirectionalDerivative usage' );

$dderiv = DirectionalDerivative 'x*y+z',
  @{ [ 'b', Math::Symbolic::Variable->new('a') ] }, @{ [ 'z', 'x' ] };
ok( $dderiv->is_identical(<<'HERE'), 'basic DirectionalDerivative usage' );
((partial_derivative((x * y) + z, z)) * (b / (((b ^ 2)
+ (a ^ 2)) ^ 0.5))) + ((partial_derivative((x * y) + z, x)
) * (a / (((b^ 2) + (a ^ 2)) ^ 0.5)))
HERE

my $taylor = TaylorPolyTwoDim 'x*y', 'x', 'y', 0;
ok(
    $taylor->is_identical(
        <<'HERE'), 'basic TaylorPolyTwoDim usage (degree 0)' );
x_0 * y_0
HERE

$taylor = TaylorPolyTwoDim 'x*y', 'x', 'y', 1;
ok(
    $taylor->is_identical(
        <<'HERE'), 'basic TaylorPolyTwoDim usage (degree 1)' );
(x_0 * y_0) + ((((x - x_0) * (partial_derivative(x_0 * y_0, x_0))) +
((y - y_0) * (partial_derivative(x_0 * y_0, y_0)))) / 1)
HERE

my @functions = ( 'x*y', 'z' );
my @vars      = ( 'x',   'z' );
my $wronsky = WronskyDet @functions, @vars;
ok( $wronsky->is_identical(<<'HERE'), 'simple Wronsky Determinant' );
(x*y)*partial_derivative(z, z) - partial_derivative(x*y, x) * z
HERE

__DATA__
$foo=bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'x'},'Math::Symbolic::Variable'),bless({'signature'=>[],'value'=>undef,'name'=>'y'},'Math::Symbolic::Variable')],'type'=>2},'Math::Symbolic::Operator'),bless({'signature'=>[],'value'=>undef,'name'=>'z'},'Math::Symbolic::Variable')],'type'=>0},'Math::Symbolic::Operator'),bless({'signature'=>[],'value'=>undef,'name'=>'x'},'Math::Symbolic::Variable')],'type'=>5},'Math::Symbolic::Operator'),bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'a'},'Math::Symbolic::Variable'),bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'a'},'Math::Symbolic::Variable'),bless({'special'=>'','value'=>'2'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator'),bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'b'},'Math::Symbolic::Variable'),bless({'special'=>'','value'=>'2'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator')],'type'=>0},'Math::Symbolic::Operator'),bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'c'},'Math::Symbolic::Variable'),bless({'special'=>'','value'=>'2'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator')],'type'=>0},'Math::Symbolic::Operator'),bless({'special'=>'','value'=>'0.5'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator')],'type'=>3},'Math::Symbolic::Operator')],'type'=>2},'Math::Symbolic::Operator'),bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'x'},'Math::Symbolic::Variable'),bless({'signature'=>[],'value'=>undef,'name'=>'y'},'Math::Symbolic::Variable')],'type'=>2},'Math::Symbolic::Operator'),bless({'signature'=>[],'value'=>undef,'name'=>'z'},'Math::Symbolic::Variable')],'type'=>0},'Math::Symbolic::Operator'),bless({'signature'=>[],'value'=>undef,'name'=>'y'},'Math::Symbolic::Variable')],'type'=>5},'Math::Symbolic::Operator'),bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'b'},'Math::Symbolic::Variable'),bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'a'},'Math::Symbolic::Variable'),bless({'special'=>'','value'=>'2'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator'),bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'b'},'Math::Symbolic::Variable'),bless({'special'=>'','value'=>'2'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator')],'type'=>0},'Math::Symbolic::Operator'),bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'c'},'Math::Symbolic::Variable'),bless({'special'=>'','value'=>'2'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator')],'type'=>0},'Math::Symbolic::Operator'),bless({'special'=>'','value'=>'0.5'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator')],'type'=>3},'Math::Symbolic::Operator')],'type'=>2},'Math::Symbolic::Operator')],'type'=>0},'Math::Symbolic::Operator'),bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'x'},'Math::Symbolic::Variable'),bless({'signature'=>[],'value'=>undef,'name'=>'y'},'Math::Symbolic::Variable')],'type'=>2},'Math::Symbolic::Operator'),bless({'signature'=>[],'value'=>undef,'name'=>'z'},'Math::Symbolic::Variable')],'type'=>0},'Math::Symbolic::Operator'),bless({'signature'=>[],'value'=>undef,'name'=>'z'},'Math::Symbolic::Variable')],'type'=>5},'Math::Symbolic::Operator'),bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'c'},'Math::Symbolic::Variable'),bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'a'},'Math::Symbolic::Variable'),bless({'special'=>'','value'=>'2'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator'),bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'b'},'Math::Symbolic::Variable'),bless({'special'=>'','value'=>'2'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator')],'type'=>0},'Math::Symbolic::Operator'),bless({'operands'=>[bless({'signature'=>[],'value'=>undef,'name'=>'c'},'Math::Symbolic::Variable'),bless({'special'=>'','value'=>'2'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator')],'type'=>0},'Math::Symbolic::Operator'),bless({'special'=>'','value'=>'0.5'},'Math::Symbolic::Constant')],'type'=>7},'Math::Symbolic::Operator')],'type'=>3},'Math::Symbolic::Operator')],'type'=>2},'Math::Symbolic::Operator')],'type'=>0},'Math::Symbolic::Operator');
