#!perl
use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
	use_ok('Math::Symbolic');
	use_ok('Math::Symbolic::MiscCalculus');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic qw/:all/;
use Math::Symbolic::ExportConstants qw/:all/;
use Math::Symbolic::MiscCalculus qw/:all/;

my $func = 'sin(x)';
my $taylor = TaylorPolynomial $func, 0, 'x', 'x_0';
ok( $taylor->is_identical('sin(x_0)'), 'simple taylor poly of 0-th degree' );

$taylor = TaylorPolynomial $func, 1, 'x';
ok( $taylor->is_identical('(sin(x_0)) + (((cos(x_0)) / 1) * ((x - x_0) ^ 1))'),
    'simple taylor poly of first degree' );

$taylor = TaylorPolynomial 'tan(a)', 3, 'a', 'b';
ok( defined $taylor, 'complex taylor poly of third degree' );

my $error = TaylorErrorLagrange 'sin(x)', 3, 'x';
ok( defined $error, 'simple lagrange error' );

$error = TaylorErrorLagrange 'tan(x)', 1, 'x', 'var';
ok( defined $error, 'more simple lagrange error' );

$error = TaylorErrorLagrange 'tan(x)', 0, 'x', 'var', 'that';
ok( defined $error, 'more simple lagrange error' );

$error = TaylorErrorCauchy 'cos(x)', 2, 'x';
ok( defined $error, 'simple cauchy error' );

$error = TaylorErrorCauchy 'sin(x)*cos(x)', 1, 'x', 'var';
ok( defined $error, 'more simple cauchy error' );

$error = TaylorErrorCauchy 'tan(x)*sin(x)', 1, 'x', 'var', 'that';
ok( defined $error, 'more simple cauchy error' );

