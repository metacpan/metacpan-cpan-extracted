#!perl -T
use strict;
use warnings;

use Test::More tests => 56;
use Math::VectorReal;
use List::Util qw(min max);
use Math::Geometry::Construction;

sub is_close {
    my ($value, $reference, $message, $limit) = @_;

    cmp_ok(abs($value - $reference), '<', ($limit || 1e-12), $message);
}

sub indexed_position {
    my $construction = Math::Geometry::Construction->new(width  => 800,
							 height => 300);

    my $l;
    my $c;
    my @ips;
    my $pos;

    $l = $construction->add_line(support => [[10, 20], [30, 20]]);
    $c = $construction->add_circle(center => [20, 20], radius => 100);
    
    @ips = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$l, $c]},
	 [{position_selector => ['indexed_position', [0]]},
	  {position_selector => ['indexed_position', [1]]}]);

    is(scalar(@ips), 2, 'two intersection points');
    foreach(@ips) {
	ok(defined($_), 'defined');
	isa_ok($_, 'Math::Geometry::Construction::DerivedPoint');
	$pos = $_->position;
	ok(defined($pos), 'position defined');
	isa_ok($pos, 'Math::Vector::Real');
	# cannot test x because I don't know which point I got
	is_close($pos->[1], 20, 'intersection y');
    }
}

sub extreme_position {
    my $construction = Math::Geometry::Construction->new(width  => 800,
							 height => 300);

    my $l;
    my $c;
    my @ips;
    my @ipps;

    $l = $construction->add_line(support => [[10, 20], [30, 20]]);
    $c = $construction->add_circle(center => [20, 20], radius => 100);
    
    @ips = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$l, $c]},
	 [{position_selector => ['extreme_position', [vector(1, 0, 0)]]},
	  {position_selector => ['extreme_position', [[-1, 0]]]},
	  {position_selector => ['extreme_position', [$l]]}]);

    is(scalar(@ips), 3, 'three intersection points');
    foreach(@ips) {
	ok(defined($_), 'defined');
	isa_ok($_, 'Math::Geometry::Construction::DerivedPoint');
    }
    foreach(@ipps = map { $_->position } @ips) {
	ok(defined($_), 'position defined');
	isa_ok($_, 'Math::Vector::Real');
    }
    is_close($ipps[0]->[0], 120, 'intersection x');
    is_close($ipps[0]->[1], 20, 'intersection y');
    is_close($ipps[1]->[0], -80, 'intersection x');
    is_close($ipps[1]->[1], 20, 'intersection y');
    is_close($ipps[2]->[0], 120, 'intersection x');
    is_close($ipps[2]->[1], 20, 'intersection y');
}

sub dist_position {
    my $construction = Math::Geometry::Construction->new(width  => 800,
							 height => 300);

    my $p;
    my $l;
    my $c;
    my @ips;
    my @ipps;

    $l = $construction->add_line(support => [[10, 20], [30, 20]]);
    $c = $construction->add_circle(center => [20, 20], radius => 100);
    
    @ips = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$l, $c]},
	 [{position_selector => ['close_position', [vector(-80, 20, 0)]]},
	  {position_selector => ['distant_position', [[-80, 20]]]}]);

    is(scalar(@ips), 2, 'two intersection points');
    foreach(@ips) {
	ok(defined($_), 'defined');
	isa_ok($_, 'Math::Geometry::Construction::DerivedPoint');
    }
    foreach(@ipps = map { $_->position } @ips) {
	ok(defined($_), 'position defined');
	isa_ok($_, 'Math::Vector::Real');
    }
    is_close($ipps[0]->[0], -80, 'intersection x');
    is_close($ipps[0]->[1], 20, 'intersection y');
    is_close($ipps[1]->[0], 120, 'intersection x');
    is_close($ipps[1]->[1], 20, 'intersection y');

    $p = $construction->add_point(position => [110, 120]);
    $l = $construction->add_line(support => [$p, [130, 120]]);
    $c = $construction->add_circle(center => [120, 120], radius => 100);
    
    @ips = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$l, $c]},
	 [{position_selector => ['close_position', [$p]]},
	  {position_selector => ['distant_position', [$p]]}]);

    is(scalar(@ips), 2, 'two intersection points');
    foreach(@ips) {
	ok(defined($_), 'defined');
	isa_ok($_, 'Math::Geometry::Construction::DerivedPoint');
    }
    foreach(@ipps = map { $_->position } @ips) {
	ok(defined($_), 'position defined');
	isa_ok($_, 'Math::Vector::Real');
    }
    is_close($ipps[0]->[0], 20, 'intersection x');
    is_close($ipps[0]->[1], 120, 'intersection y');
    is_close($ipps[1]->[0], 220, 'intersection x');
    is_close($ipps[1]->[1], 120, 'intersection y');
}

indexed_position;  # this has already been tested in 010
extreme_position;
dist_position;
