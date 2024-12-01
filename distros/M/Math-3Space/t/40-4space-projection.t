#! /usr/bin/env perl
use Test2::V0;
use Math::3Space qw( vec3 space frustum perspective );

sub mat_check {
	return [ map float($_, tolerance => 1e-5), @_ ];
}

# Tests created with
# perl -E 'use strict; use warnings;
#  use OpenGL::Sandbox qw/ -V1 make_context get_matrix glMatrixMode GL_PROJECTION glFrustum GL_PROJECTION_MATRIX /;
#  make_context; glMatrixMode(GL_PROJECTION); glFrustum(-1,1,-1,1,1,1000); say join ", ", get_matrix(GL_PROJECTION_MATRIX);'
# (and then truncating to 32-bit float precision because that's all OpenGL stores)

my $p= frustum(-1,1,-1,1,1,1000);
is( [ $p->matrix_colmajor ], mat_check(
	# note - this is transposed because GL is column-major order,
	# but the goal is for the sequence of integers from matrix_colmajor
	# to match the sequence from glGetDouble, which this accurately tests.
	1, 0, 0, 0,
	0, 1, 0, 0,
	0, 0, -1.002002002, -1,
	0, 0, -2.002002002, 0
), 'simple 2x2x999 frustum' );

is( [ $p->matrix_colmajor(space) ], mat_check(
	1, 0, 0, 0,
	0, 1, 0, 0,
	0, 0, -1.002002002, -1,
	0, 0, -2.002002002, 0
), 'simple 2x2x999 frustum times Identity space' );

is( [ $p->matrix_colmajor(space->rotate(.5, [1,.9,.8])->travel(.1,.2,.3)) ], mat_check(
	-0.18367, 0.73469, -0.65437, -0.65306,
	0.73469, -0.33878, -0.58893, -0.58775,
	0.65306,  0.58775,  0.47851,  0.47756,
	0.32449,  0.18204, -2.04167, -0.03959,
), 'simple 2x2x999 frustum times rotated translated space' );

$p= frustum(-.5,1.5, -.5,1.5, 1,101);
is( [ $p->matrix_colmajor(space) ], mat_check(
	1, 0, 0, 0,
	0, 1, 0, 0,
	0.5, 0.5, -1.02, -1,
	0, 0, -2.02, 0
), 'off-center frustum times Identity space' );

$p= perspective(1/4, 1, 1, 1000);
is( [ $p->matrix_colmajor(space) ], mat_check(
	1, 0, 0, 0,
	0, 1, 0, 0,
	0, 0, -1.002002002, -1,
	0, 0, -2.002002002, 0
), 'perspective 90deg 1:1 aspect 999 deep frustum times Identity space' );

$p= perspective(1/4, 4/3, .1, 1000);
is( [ $p->matrix_colmajor(space) ], mat_check(
	0.74999999, 0, 0, 0,
	0, 1, 0, 0,
	0, 0, -1.00020002, -1,
	0, 0, -0.200020002, 0
), 'perspective 90deg 4:3 aspect 999.9 deep frustum times Identity space' );

is( [ unpack 'f*', $p->matrix_pack_float  ], mat_check($p->matrix_colmajor), 'matrix_pack_float' );
is( [ unpack 'd*', $p->matrix_pack_double ], mat_check($p->matrix_colmajor), 'matrix_pack_double' );

subtest back_compat => sub {
	use Math::3Space 'perspective_projection';
	my $matrix= perspective_projection(1/4, 1, 1, 1000);
	is( [$matrix->get_gl_matrix(space)], mat_check(
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, -1.002002002, -1,
		0, 0, -2.002002002, 0
	), 'get_gl_matrix on perspective_projection function' );
};

done_testing;
