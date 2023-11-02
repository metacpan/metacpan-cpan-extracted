#! /usr/bin/env perl
use Test2::V0;
use Math::3Space 'space', 'vec3';

sub vec_check {
	my ($x, $y, $z)= @_;
	return object { call sub { [shift->xyz] }, [ float($x), float($y), float($z) ]; }
}
sub mat_check {
	return [ map float($_), @_ ];
}

# use OpenGL qw( GL_MODELVIEW_MATRIX glLoadIdentity glTranslatef glGetFloatv_p );
# use OpenGL::Sandbox "-V1", ":all";
# make_context; setup_projection; next_frame;
# glLoadIdentity(); rotate(x => 90); printf("%.5lf\n", $_) for glGetFloatv_p(GL_MODELVIEW_MATRIX);
subtest get_gl_matrix => sub {
	my $s= space;
	is( [ $s->get_gl_matrix ], mat_check(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1), 'identity' );
	$s->get_gl_matrix(my $buf);
	is( $buf, pack(d16 => (1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)), 'identity buffer' );

	$s->translate([ 2,3,4 ]);
	is( [ $s->get_gl_matrix ], mat_check(1,0,0,0, 0,1,0,0, 0,0,1,0, 2,3,4,1), 'tr 2,3,4' );
	$s->get_gl_matrix($buf);
	is( $buf, pack(d16 => (1,0,0,0, 0,1,0,0, 0,0,1,0, 2,3,4,1)), 'tr 2,3,4 buffer' );

	$s= space->rot_x(.25);
	is( [ $s->get_gl_matrix ], mat_check(1,0,0,0, 0,0,1,0, 0,-1,0,0, 0,0,0,1), 'rot x .25' );

	$s= space->scale(2);
	is( [ $s->get_gl_matrix ], mat_check(2,0,0,0, 0,2,0,0, 0,0,2,0, 0,0,0,1), 'scale 2' );
};

done_testing;
