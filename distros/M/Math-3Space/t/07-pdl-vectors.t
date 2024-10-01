#! /usr/bin/env perl
use Test2::V0;
use Math::3Space 'space', 'vec3';
BEGIN { eval {require PDL;1} or skip_all("No PDL") }
use PDL::Lite;
use Scalar::Util 'refaddr';

sub vec_check {
	my ($x, $y, $z)= @_;
	return object { call sub { [shift->xyz] }, [ float($x), float($y), float($z) ]; }
}
sub pdl_check {
	my (@list)= @_;
	return object { call sub { [shift->list] }, [ map float($_), @list ]; }
}
sub mat_check {
	return [ map float($_), @_ ];
}

subtest assign_from_pdl_vec => sub {
	my $s= space;
	$s->xv(pdl([1,0,1]));
	is( $s->xv, vec_check(1,0,1), 'assign xv from pdl' );

	# Check again using different storage than NV
	$s->yv(PDL::Core::float([0,.5,1]));
	is( $s->yv, vec_check(0,.5,1), 'assign yv from pdl floats' );
};

subtest project_pdl_vec => sub {
	my $s= space->translate(0,0,.5)->rot_z(.25);
	is( $s->project(pdl(1,0,0)),      pdl_check(0,-1,-.5), 'project' );
	is( $s->unproject(pdl(0,-1,-.5)), pdl_check(1,0,0),    'unproject' );
	is( $s->project_vector(pdl(1,0,0)),    pdl_check(0,-1,0), 'project_vector' );
	is( $s->unproject_vector(pdl(0,-1,0)), pdl_check(1,0,0),  'unproject_vector' );

	my $pdl= pdl(1,0,0);
	$s->project_inplace($pdl);
	is( $pdl, pdl_check(0,-1,.5), 'project_inplace' );
	$s->unproject_inplace($pdl);
	is( $pdl, pdl_check(1,0,0), 'unproject_inplace' );
	$s->project_vector_inplace($pdl);
	is( $pdl, pdl_check(0,-1,0), 'project_vector_inplace' );
	$s->unproject_vector_inplace($pdl);
	is( $pdl, pdl_check(1,0,0), 'unproject_vector_inplace' );

	$pdl= pdl([1,0,0], [0,1,0], [0,0,1]);
	$s->project_inplace($pdl);
	is( $pdl->slice(',0'), pdl_check(0,-1,0.5), 'project_inplace multi ,0' );
	is( $pdl->slice(',1'), pdl_check(1,0,0.5),  'project_inplace multi ,1' );
	is( $pdl->slice(',2'), pdl_check(0,0,1.5),  'project_inplace multi ,2' );

	# Check again using different storage than NV
	$pdl= PDL::Core::float([1,0,0], [0,1,0], [0,0,1]);
	$s->project_inplace($pdl);
	is( $pdl->slice(',0'), pdl_check(0,-1,0.5), 'project_inplace float multi ,0' );
	is( $pdl->slice(',1'), pdl_check(1,0,0.5),  'project_inplace float multi ,1' );
	is( $pdl->slice(',2'), pdl_check(0,0,1.5),  'project_inplace float multi ,2' );
};

done_testing;
