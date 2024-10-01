#! /usr/bin/env perl
use Test2::V0;
use Math::3Space qw( vec3 space frustum_projection perspective_projection );

sub vec_check {
	my ($x, $y, $z)= @_;
	return object { call sub { [shift->xyz] }, [ float($x), float($y), float($z) ]; }
}

my $s= space;

# Not verified! TODO: check vs another implementation, and test more combinations.
my $p= perspective_projection(1/4, 4/3, 1, 100);
is( [ $p->get_gl_matrix($s) ], [ map float($_),
	0.75, 0,  0,  0,
	0   , 1,  0,  0,
	0   , 0, -1, -1,
	0   , 0, -1,  0
], 'perspective get_gl_matrix' );

done_testing;
