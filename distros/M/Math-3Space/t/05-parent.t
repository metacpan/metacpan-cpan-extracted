#! /usr/bin/env perl
use Test2::V0;
use Math::3Space 'space', 'vec3';

sub vec_check {
	my ($x, $y, $z)= @_;
	return object { call sub { [shift->xyz] }, [ float($x), float($y), float($z) ]; }
}

subtest parent_graph_checks => sub {
	# detect cycles
	my @spaces= (space->rot(.25, [1,1,1]));
	push @spaces, $spaces[-1]->space for 1..100;
	is( $spaces[-1]->parent_count, 100, 'tree is 100 deep' );
	is( $spaces[$_]->parent_count, $_, "parent count of $_" )
		for 62..66; # cross threshold where it starts checking for cycles

	is( eval { $spaces[-5]->reparent($spaces[-1]) }, undef, "can't reparent" );
	like( $@, qr/cycle/i, 'error about cycles' );

	is( eval { $spaces[0]->reparent($spaces[-5]) }, undef, "can't reparent" );
	like( $@, qr/cycle/i, 'error about cycles' );

	is( eval { $spaces[11]->reparent($spaces[0]) }, $spaces[11], "reparent 11 under 0" );
	is( $spaces[11]->parent_count, 1, 'space 11 has one parent now' );
	is( $spaces[-1]->parent_count, 90, 'space 100 has 90 parents now' );
};

subtest unproject_space => sub {
	my $sp1= space->rot_z(.125);
	my $sp2= $sp1->space->rot_z(.125);
	my $sp3= $sp2->space->rot_z(.125);
	my $sp4= $sp3->space->rot_z(.125);

	# Space 4 should be a complete .5 rotation, with X and Y axes pointing opposite direction.
	my $v= vec3(1,0,0);
	$_->unproject_inplace($v) for $sp4, $sp3, $sp2, $sp1;
	is( $v, vec_check(-1,0,0), 'unproject each makes .5 rotation' );

	# Now reparent space 4 to be global
	$sp4->reparent(undef);
	is( $sp4->parent_count, 0, 'sp4 has no parents' );
	# Now unprojecting from sp4 alone should make a .5 rotation.
	is( $sp4->unproject(vec3(1,0,0)), vec_check(-1,0,0), 'unproject sp4 makes .5 rotation' );
};

subtest project_space => sub {
	my $sp1= space->rot(.125, [1,1,1])->tr(5,0,0)->rot_z(.4)->tr(5,4,3);
	my $sp2= $sp1->space->tr(0,2,1)->rot_z(.2345);
	# take a second space in global parent space, and project it into sp2
	my $spb= space->tr(-1,-1,-1)->reparent($sp2);
	# Now projecting => sp1 => sp2 => spb should result in the same as translating (1,1,1)
	# no matter what sp1 or sp2 were.
	my $vec= vec3(2,3,4);
	$_->project_inplace($vec) for $sp1, $sp2, $spb;
	is( $vec, vec_check(3,4,5), 'point is offset (1,1,1)' );
};

subtest reproject_space_via_common_parent => sub {
	my $sp1= space->rot(.55, [1,2,3])->tr(4,0,4)->space->rot_x(.1);
	my $sp2= $sp1->space->tr(-1,-1,-1);
	my $sp3= $sp1->space->space->rot_y(.25);
	# to take a point from sp3 and translate to sp2 should rotate .25 around Y, then
	# translate by (1,1,1).
	my $vec= vec3(1,1,1);
	$sp3->unproject_inplace($vec);
	$sp3->parent->unproject_inplace($vec);
	$sp3->parent->parent->unproject_inplace($vec);
	$sp2->parent->project_inplace($vec);
	$sp2->project_inplace($vec);
	is( $vec, vec_check(2,2,0), 'transform vec the long way' );
	# now reparent a clone of sp2 into sp3 so that we can just project into that
	my $sp2_in_sp3= $sp2->clone->reparent($sp3);
	is( $sp2_in_sp3->project(vec3(1,1,1)), vec_check(2,2,0), 'transform vec the short way' );
};

done_testing;
