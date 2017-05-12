#!perl -T
use strict;
use warnings;

use Test::More tests => 109;
use Test::Exception;
use List::Util qw(min max);
use Math::Geometry::Construction;

sub is_close {
    my ($value, $reference, $message, $limit) = @_;

    cmp_ok(abs($value - $reference), '<', ($limit || 1e-12), $message);
}

sub position_ok {
    my ($pos, $x, $y) = @_;

    ok(defined($pos), 'position is defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'position has 2 components');

    if(defined($x)) {
	is($pos->[0], $x, "x coordinate is $x");
    }
    if(defined($y)) {
	is($pos->[1], $y, "y coordinate is $y");
    }
}

sub derived_point_ok {
    my ($dp, $x, $y) = @_;

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    position_ok($dp->position, $x, $y);
}

sub circle_line {
    my $construction = Math::Geometry::Construction->new(width  => 800,
							 height => 300);
    my $l;
    my $c;
    my $dp;
    my @dps;

    $l = $construction->add_line(support => [[10, 30], [30, 30]]);
    $c = $construction->add_circle(center => [20, 30], radius => 30);
    
    $dp = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$l, $c]});
    # cannot test x because I don't know which point I got
    derived_point_ok($dp, undef, 30);

    @dps = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$c, $l]},
	 [{position_selector => ['indexed_position', [0]]},
	  {position_selector => ['indexed_position', [1]]}]);

    foreach $dp (@dps) { derived_point_ok($dp, undef, 30) }

    is_close(min(map { $_->position->[0] } @dps), -10, 'intersection x');
    is_close(max(map { $_->position->[0] } @dps), 50, 'intersection x');
}

sub id {
    my $construction = Math::Geometry::Construction->new;
    my $line;
    my $circle;
    my $d;
    my $dp;
    my %count;

    $line = $construction->add_line(support => [[10, 30], [30, 30]]);
    $circle = $construction->add_circle(center  => [20, 30],
					support => [20, 60]);

    $d = $construction->add_derivate
	('IntersectionCircleLine', input => [$line, $circle]);
    is($d->order_index, $construction->count_objects - 1,
       'derivate is last object');
    is($d->id,
       sprintf(Math::Geometry::Construction::Derivate->id_template,
	       $d->order_index),
       'derivate id is composed from id_template and order_index');

    $dp = $d->create_derived_point;
    is($dp->order_index, $construction->count_objects - 1,
       'derived point is last object');
    is($dp->id,
       sprintf(Math::Geometry::Construction::DerivedPoint->id_template,
	       $dp->order_index),
       'derived point id is composed from id_template and order_index');

    $dp = $construction->add_derived_point
	('IntersectionCircleLine', {input => [$circle, $line]});
    is($dp->order_index, $construction->count_objects - 1,
       'derived point is last object');
    is($dp->id,
       sprintf(Math::Geometry::Construction::DerivedPoint->id_template,
	       $dp->order_index),
       'derived point id is composed from id_template and order_index');
    ok(defined($dp->derivate), 'derivate exists');
    ok(defined($construction->object($dp->derivate->id)),
       'derivate can be found via id');

    $dp = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$construction->add_line(support => [[1, 2], [3, 4]]),
		    $construction->add_circle(support => [5, 6],
					      center  => [7, 8])]});

    %count = ();
    foreach($construction->objects) {
	$count{$_->order_index} = 1;
    }
    is(scalar(keys %count), $construction->count_objects,
       'order_indices are unique');

    %count = ();
    foreach($construction->objects) {
	$count{$_->id} = 1;
    }
    is(scalar(keys %count), $construction->count_objects,
       'ids are unique');
}

sub input {
    my $construction = Math::Geometry::Construction->new;
    my @template;
    my $line;
    my $circle;
    my $d;

    $line   = $construction->add_line(support => [[10, 30], [30, 30]]);
    $circle = $construction->add_circle(center  => [20, 30],
					support => [20, 60]);
    
    $d = $construction->add_derivate
	('IntersectionCircleLine', input => [$line, $circle]);
    is($d->count_input, 2, 'count_input works and delivers 2');
    ($circle, $line) = $d->input;
    isa_ok($circle, 'Math::Geometry::Construction::Circle');
    isa_ok($line, 'Math::Geometry::Construction::Line');
    isa_ok($d->single_input(0),
	   'Math::Geometry::Construction::Circle');
    isa_ok($d->single_input(1),
	   'Math::Geometry::Construction::Line');

    @template = ([$line],
		 $line,
		 [$circle],
		 $circle,
		 [$line, $line],
		 [$circle, $circle->center]);
    
    foreach(@template) {
	throws_ok(sub { $construction->add_derivate
			('IntersectionCircleLine', input => $_); },
		  qr/type constraint/,
		  'CircleLine type constraint');
    }
}

sub register_derived_point {
    my $construction = Math::Geometry::Construction->new;
    my $line;
    my $circle;
    my $dp;

    $line   = $construction->add_line(support => [[1, 2], [3, 4]]);
    $circle = $construction->add_circle(center  => [1, 0],
					support => [5, 6]);
    $dp = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$line, $circle]});

    is(scalar(grep { $_->id eq $dp->id } $line->points), 1,
       'derived point is registered');
    is(scalar(grep { $_->id eq $dp->id } $circle->points), 1,
       'derived point is registered');
}

sub overloading {
    my $construction = Math::Geometry::Construction->new;

    my $line;
    my $circle;
    my $dp;

    $line = $construction->add_line(support => [[10, 30], [30, 30]]);
    $circle = $construction->add_circle(center => [20, 30], radius => 30);
    
    $dp = $line x $circle;
    derived_point_ok($dp, -10, 30);
    
    $dp = $circle x $line;
    derived_point_ok($dp, -10, 30);
}

sub partial_draw {
    my $construction = Math::Geometry::Construction->new;
    my $circle;
    my $line;
    my @dps;
    my @bp;

    $circle = $construction->add_circle(center  => [0, 0],
					support => [5, 0]);
    is_deeply([$circle->_calculate_boundary_positions],
	      [[undef, undef], [undef, undef]],
	      'one point, no boundary points');

    $line = $construction->add_line(support => [[4, -1], [4, 1]]);
    @dps  = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$circle, $line]},
	 [{position_selector => ['indexed_position', [0]]},
	  {position_selector => ['indexed_position', [1]]}]);

    @bp = $circle->_calculate_boundary_positions;
    position_ok($bp[0], 4, -3);
    position_ok($bp[1], 4, 3);

    $circle = $construction->add_circle(center  => [0, 0],
					support => [-5, 0]);
    $line = $construction->add_line(support => [[-4, -1], [-4, 1]]);
    @dps  = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$circle, $line]},
	 [{position_selector => ['indexed_position', [0]]},
	  {position_selector => ['indexed_position', [1]]}]);

    @bp = $circle->_calculate_boundary_positions;
    position_ok($bp[0], -4, 3);
    position_ok($bp[1], -4, -3);

    $circle = $construction->add_circle(center  => [0, 0],
					support => [0, 5]);
    $line = $construction->add_line(support => [[-1, 3], [1, 3]]);
    @dps  = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$circle, $line]},
	 [{position_selector => ['indexed_position', [0]]},
	  {position_selector => ['indexed_position', [1]]}]);

    @bp = $circle->_calculate_boundary_positions;
    position_ok($bp[0], 4, 3);
    position_ok($bp[1], -4, 3);

    $circle = $construction->add_circle(center  => [0, 0],
					support => [0, -5]);
    $line = $construction->add_line(support => [[-1, -3], [1, -3]]);
    @dps  = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$circle, $line]},
	 [{position_selector => ['indexed_position', [0]]},
	  {position_selector => ['indexed_position', [1]]}]);

    @bp = $circle->_calculate_boundary_positions;
    position_ok($bp[0], -4, -3);
    position_ok($bp[1], 4, -3);

    # check support involvement
    $circle = $construction->add_circle(center  => [0, 0],
					support => [5, 0]);
    $line = $construction->add_line(support => [[-1, -3], [1, -3]]);
    @dps  = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$circle, $line]},
	 [{position_selector => ['indexed_position', [0]]},
	  {position_selector => ['indexed_position', [1]]}]);

    @bp = $circle->_calculate_boundary_positions;
    position_ok($bp[0], -4, -3);
    position_ok($bp[1], 5, 0);

    # check closed circle
    $circle = $construction->add_circle(center  => [0, 0],
					support => [5, 0]);
    $line = $construction->add_line(support => [[0, 0], [1, 0]]);
    @dps  = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$circle, $line]},
	 [{position_selector => ['indexed_position', [0]]},
	  {position_selector => ['indexed_position', [1]]}]);
    $line = $construction->add_line(support => [[0, 0], [0.1, 1]]);
    @dps  = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$circle, $line]},
	 [{position_selector => ['indexed_position', [0]]},
	  {position_selector => ['indexed_position', [1]]}]);
    $line = $construction->add_line(support => [[0, 0], [-0.1, 1]]);
    @dps  = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$circle, $line]},
	 [{position_selector => ['indexed_position', [0]]},
	  {position_selector => ['indexed_position', [1]]}]);

    is_deeply([$circle->_calculate_boundary_positions],
	      [[undef, undef], [undef, undef]],
	      'too many points, no boundary points');
}

circle_line;
id;
input;
register_derived_point;
overloading;
partial_draw;
