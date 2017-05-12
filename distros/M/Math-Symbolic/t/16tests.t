#!perl
use strict;
use warnings;

use Test::More tests => 48;

BEGIN {
	use_ok('Math::Symbolic');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic qw/:all/;
use Math::Symbolic::ExportConstants qw/:all/;

my $x = Math::Symbolic::parse_from_string('1');
ok( $x->is_constant(), 'is_constant true for constants' );

$x = Math::Symbolic::parse_from_string('a');
ok( !$x->is_constant(), 'is_constant false for vars' );

$x = Math::Symbolic::parse_from_string('1+1/5*log(2,3)^5');
ok( $x->is_constant(), 'is_constant true for constant expressions' );

$x = Math::Symbolic::parse_from_string('1+1/5*log(2,a)^5');
ok( !$x->is_constant(), 'is_constant false for non-constant expressions' );

$x =
  Math::Symbolic::parse_from_string('partial_derivative(1+1/5*log(2,2)^5-a,a)');
ok( $x->is_constant(),
    'is_constant true for expressions that become constant after del/delx' );

$x =
  Math::Symbolic::parse_from_string('total_derivative(1+1/5*log(2,2)^5-a,a)');
ok( $x->is_constant(),
    'is_constant true for expressions that become constant after d/dx' );

$x =
  Math::Symbolic::parse_from_string(
    'total_derivative(b(a)+1/5*log(2,2)^5-a,a)');
ok( !$x->is_constant(),
    'is_constant true for expressions that become constant after d/dx' );

$x = Math::Symbolic::parse_from_string('a');
ok( !$x->is_integer(), 'is_integer false for vars' );

$x = Math::Symbolic::parse_from_string('1.5');
ok( !$x->is_integer(), 'is_integer false for fractions' );

$x = Math::Symbolic::parse_from_string('2000');
ok( $x->is_integer(), 'is_integer true for integers' );

$x = Math::Symbolic::parse_from_string('0');
ok( $x->is_integer(), 'is_integer true for zero' );

$x = Math::Symbolic::parse_from_string('2000*2000');
ok( !$x->is_integer(), 'is_integer false for operators' );

$x = Math::Symbolic::parse_from_string('1');
ok( $x->is_sum(), 'is_sum true for constant' );

$x = Math::Symbolic::parse_from_string('1+2');
ok( $x->is_sum(), 'is_sum true for constant sum' );

$x = Math::Symbolic::parse_from_string('1*a');
ok( $x->is_sum(), 'is_sum true for constant times variable' );

$x = Math::Symbolic::parse_from_string('1*a');
ok( $x->is_sum(), 'is_sum true for integer constant times variable' );

$x = Math::Symbolic::parse_from_string('1.5*a');
ok( !$x->is_sum(), 'is_sum false for non-integer constant times variable' );

$x = Math::Symbolic::parse_from_string('1*a+(-b)-3*sin(2)');
ok( $x->is_sum(), 'is_sum true for sum of variables and constant terms' );

$x =
  Math::Symbolic::parse_from_string(
    'partial_derivative(10*a^2+(-1/b)-3*sin(2),a)');
ok( $x->is_sum(), 'is_sum true for del/delx that evaluates to a sum' );

my $y =
  Math::Symbolic::parse_from_string(
    'partial_derivative(10*a^2+(-1/b(x))-3*sin(2),a)');
$x =
  Math::Symbolic::parse_from_string(
    'partial_derivative(10*a^2+(-1/b(x))-3*sin(2),a)');
ok( $x->is_identical($y), 'is_identical true involved term' );

$y =
  Math::Symbolic::parse_from_string(
    'total_derivative(10*a^2+(-1/b(x))-3*sin(c(d,f,g,i,a)-2),a)');
$x =
  Math::Symbolic::parse_from_string(
    'total_derivative(10*a^2+(-1/b(x))-3*sin(c(d,f,g,i,a)-2),a)');
ok( $x->is_identical($y), 'is_identical true involved term' );

$y =
  Math::Symbolic::parse_from_string(
    'total_derivative(10*a^2+(-1/b(a))-3*sin(2),a)');
$x =
  Math::Symbolic::parse_from_string(
    'total_derivative(10*a^2+(-1/b(x))-3*sin(2),a)');
ok( !$x->is_identical($y),
    'is_identical false involved term differing in signature' );

$y =
  Math::Symbolic::parse_from_string(
    'total_derivative(10*a^2+(-2/b(x))-3*sin(2),a)');
$x =
  Math::Symbolic::parse_from_string(
    'total_derivative(10*a^2+(-1/b(x))-3*sin(2),a)');
ok( !$x->is_identical($y),
    'is_identical false involved term differing in constant' );

$y =
  Math::Symbolic::parse_from_string(
    'total_derivative(10*x^2+(-1/b(x))-3*sin(2),a)');
$x =
  Math::Symbolic::parse_from_string(
    'total_derivative(10*a^2+(-1/b(x))-3*sin(2),a)');
ok( !$x->is_identical($y),
    'is_identical false involved term differing in variable' );

$y =
  Math::Symbolic::parse_from_string(
    'total_derivative(10*a^2+(-1*b(x))-3*sin(2),a)');
$x =
  Math::Symbolic::parse_from_string(
    'total_derivative(10*a^2+(-1/b(x))-3*sin(2),a)');
ok( !$x->is_identical($y),
    'is_identical false involved term differing in operator' );

ok(
    (
              $x->can('descend')
          and defined( ref( $x->can('descend') ) )
          and ref( $x->can('descend') ) eq 'CODE'
    ),
    'can() returns code ref for builtin method.'
);

ok(
    (
              $x->can('is_constant')
          and defined( ref( $x->can('is_constant') ) )
          and ref( $x->can('is_constant') ) eq 'CODE'
    ),
    'can() returns code ref for delegated method.'
);

ok( !$x->can('bdasjkhdsajhdsakasjlh'),
    'can() returns false for non-existant builtin method.' );

ok( !$x->can('is_ashdgsajhgdasjhg'),
    'can() returns false for non-existant delegated method.' );

ok( parse_from_string('x*y')->is_identical_base('x*y'),
    'is_identical_base trivial' );

ok( parse_from_string('(x*y)^2')->is_identical_base('x*y'),
    'is_identical_base simple' );

ok( parse_from_string('(x*y)^(a*b)')->is_identical_base('x*y'),
    'more is_identical_base tests' );

ok( parse_from_string('(x*y)^(a*b)')->is_identical_base('(x*y)^3'),
    'more is_identical_base tests' );

ok( parse_from_string('(x*y^3)')->is_identical_base('(x*y^3)^3'),
    'more is_identical_base tests' );

ok( not( parse_from_string('(y)^(a*b)')->is_identical_base('(x*y)^3') ),
    'more is_identical_base tests' );

ok( parse_from_string('1')->is_one(), '1 is_one' );
ok( !parse_from_string('0')->is_one(), '!0 is_one' );
ok( !parse_from_string('4-3')->is_one(), '!4-3 is_one' );
ok( !parse_from_string('a')->is_one(), '!a is_one' );

ok( !parse_from_string('1')->is_zero(), '!1 is_zero' );
ok( parse_from_string('0')->is_zero(), '!0 is_zero' );
ok( !parse_from_string('4-4')->is_zero(), '!4-4 is_zero' );
ok( !parse_from_string('a')->is_zero(), '!a is_zero' );

ok( parse_from_string('1')->is_zero_or_one(), '1 is_zero_or_one' );
ok( parse_from_string('0')->is_zero_or_one(), '0 is_zero_or_one' );
ok( !parse_from_string('4-4')->is_zero_or_one(), '!4-4 is_zero_or_one' );
ok( !parse_from_string('a')->is_zero_or_one(), '!a is_zero_or_one' );

