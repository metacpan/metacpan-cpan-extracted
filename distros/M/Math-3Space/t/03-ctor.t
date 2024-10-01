#! /usr/bin/env perl
use Test2::V0;
use Math::3Space 'space';

sub check_vec {
	my ($x, $y, $z)= @_;
	return object { call sub { [shift->xyz] }, [ $x, $y, $z ]; }
}

is( Math::3Space::space(), object {
	call xv     => check_vec(1, 0, 0);
	call yv     => check_vec(0, 1, 0);
	call zv     => check_vec(0, 0, 1);
	call origin => check_vec(0, 0, 0);
	call parent => undef;
}, 'global ctor' );

is space(), '[
 [1 0 0]
 [0 1 0]
 [0 0 1]
 [0 0 0]
]
', 'stringify';

is( my $s1= space(), object {
	call xv     => check_vec(1, 0, 0);
	call yv     => check_vec(0, 1, 0);
	call zv     => check_vec(0, 0, 1);
	call origin => check_vec(0, 0, 0);
	call parent => undef;
}, 'imported ctor' );

is( $s1->space, object {
	call xv     => check_vec(1, 0, 0);
	call yv     => check_vec(0, 1, 0);
	call zv     => check_vec(0, 0, 1);
	call origin => check_vec(0, 0, 0);
	call parent => $s1;
}, 'derived space' );

my $s2= $s1->space->rotate(.5, [1,1,1]);
is( $s2->clone, object {
	call xv   => check_vec($s2->xv->xyz);
	call yv   => check_vec($s2->yv->xyz);
	call zv   => check_vec($s2->zv->xyz);
	call parent => $s2->parent;
	call parent_count => $s2->parent_count;
}, 'clone' );

# Test accessors
for my $name (qw( origin xv yv zv )) {
	my $m= $s1->can($name);
	is( $s1->$m(1,2,3)->$m,   check_vec(1,2,3), "write $name (,,)" );
	my $vec= $s1->$m;
	is( $s1->$m([2,3,4])->$m, check_vec(2,3,4), "write $name [,,]" );
	is( $s1->$m( $vec )->$m,  check_vec(1,2,3), "write $name vec()" );
}

done_testing;
