#!perl
use strict;
use warnings;

use Test::More tests => 13;

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
use Math::Symbolic::MiscAlgebra qw/:all/;

# Test det internals

my @mat = (
	[1, 2, 3, 4, 5],
	[2, 3, 4, 5, 6],
	[3, 4, 5, 6, 7],
);

my $mslice = Math::Symbolic::MiscAlgebra::_matrix_slice(\@mat, 1, 1);

my $resmat = [
	[1, 3, 4, 5],
	[3, 5, 6, 7],
];
is_deeply($mslice, $resmat, "matrix_slice(..., 1, 1)");

$mslice = Math::Symbolic::MiscAlgebra::_matrix_slice(\@mat, 0, 0);
$resmat = [
	[3,4,5,6],
	[4,5,6,7],
];
is_deeply($mslice, $resmat, "matrix_slice(..., 0, 0)");

$mslice = Math::Symbolic::MiscAlgebra::_matrix_slice(\@mat, 2, 1);
$resmat = [
	[1,3,4,5],
	[2,4,5,6],
];
is_deeply($mslice, $resmat, "matrix_slice(..., 2, 1)");

@mat = (
	[3, -2, 1, 5],
	[6, 1,  3, 0],
	[2, -5, 1, 7],
	[1, 2,  3, 5],
);

my $d = det @mat;
ok(abs($d->value() - 256)<1e-20, 'det(4x4)');

my @matrix = ( [ 'x', 'y' ], [ 'z', 'a' ], );

ok( det(@matrix)->is_identical('(x * a) - (z * y)'), '2x2 det' );

my $m = [ [qw/2 4 6/], [qw/1 3 7/], [qw/3 3 -2/], ];
my $v = [qw/12 16 -9/];

my $vec = linear_solve( $m, $v );

my $solution = [ 1, -2, 3 ];
foreach (@$vec) {
    ok( $_->value() == shift @$solution, 'linear_solve component' );
}

ok( bell_polynomial(0)->is_identical('1'),       'bell_polynomial(0)' );
ok( bell_polynomial(1)->is_identical('x'),       'bell_polynomial(1)' );
ok( bell_polynomial(2)->is_identical('x^2 + x'), 'bell_polynomial(2)' );

