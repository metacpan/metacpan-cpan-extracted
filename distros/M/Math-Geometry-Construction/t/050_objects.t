#!perl -T
use strict;
use warnings;

use Test::More tests => 148;
use Test::Exception;
use Math::Geometry::Construction;

sub order_index {
    my $construction;
    my $object;
    my @objects;

    $construction = Math::Geometry::Construction->new;
    is($construction->count_objects, 0, 'no objects to start with');

    $object = $construction->add_point(position => [0, 0]);
    is($object->order_index, 0, 'order index 0');
    is($construction->count_objects, 1, '1 object');

    @objects = ($construction->add_point(position => [0, 0]),
		$construction->add_point(position => [1, 0]));
    is($construction->count_objects, 3, '3 objects');
    $object  = $construction->add_line(support => [@objects]);
    is($object->order_index, 3, 'order index 3');
    is($construction->count_objects, 4, '4 objects');

    $object = $construction->add_line(support => [[1, 2], [3, 4]]);
    is($construction->count_objects, 7, '7 objects');    

    $object = $construction->add_circle(center  => [3, 4],
					support => [1, 2]);
    is($construction->count_objects, 10, '10 objects');    

    my %count = ();
    foreach($construction->objects) {
	$count{$_->order_index} = 1;
    }
    is(scalar(keys %count), $construction->count_objects,
       'order_indices are unique');
}

sub id {
    my $construction;
    my $object;
    my @objects;

    $construction = Math::Geometry::Construction->new;

    $object = $construction->add_point(position => [5, -7]);
    is($construction->count_objects, 1, '1 object');
    is($object->id, 'P000000000', 'automatic point id');
    $object = $construction->object('P000000000');
    ok(defined($object), 'object by id defined');
    is($object->id, 'P000000000', '...and has the expected id');
    is($object->position->[0], 5, 'position x');
    is($object->position->[1], -7, 'position y');

    $object = $construction->object('L000000000');
    ok(!defined($object), 'object by invalid id undefined');

    $object = $construction->add_point(position => [6, -8]);
    is($construction->count_objects, 2, '2 objects');
    is($object->id, 'P000000001', 'automatic point id');

    $object = $construction->add_point(position => [7, -9],
				       id       => 'foo');
    is($construction->count_objects, 3, '3 objects');
    is($object->id, 'foo', 'specified point id');
    $object = $construction->object('foo');
    ok(defined($object), 'object by id defined');
    is($object->id, 'foo', '...and has the expected id');
    is($object->position->[0], 7, 'position x');
    is($object->position->[1], -9, 'position y');

    $object = $construction->add_point(position => [8, -10]);
    is($construction->count_objects, 4, '4 objects');
    is($object->id, 'P000000003', 'automatic point id keeps counting');

    $object = $construction->add_line(support => [[1, 2], [3, 4]]);
    is($construction->count_objects, 7, '7 objects');    
    is($object->id,
       sprintf(Math::Geometry::Construction::Line->id_template,
	       $object->order_index),
       'line id is composed from id_template and order_index');
    @objects = $object->support;
    is($objects[0]->id,
       sprintf(Math::Geometry::Construction::Point->id_template,
	       $objects[0]->order_index),
       'implicit point id is composed from id_template and order_index');
    is($objects[0]->position->[0], 1, 'position x');
    is($objects[0]->position->[1], 2, 'position y');
    is($objects[1]->id,
       sprintf(Math::Geometry::Construction::Point->id_template,
	       $objects[1]->order_index),
       'implicit point id is composed from id_template and order_index');
    is($objects[1]->position->[0], 3, 'position x');
    is($objects[1]->position->[1], 4, 'position y');

    $object = $construction->add_circle(center  => [5, 6],
					support => [7, 8]);
    is($construction->count_objects, 10, '10 objects');    
    is($object->id,
       sprintf(Math::Geometry::Construction::Circle->id_template,
	       $object->order_index),
       'circle id is composed from id_template and order_index');
    @objects = ($object->center, $object->support);
    is($objects[0]->id,
       sprintf(Math::Geometry::Construction::Point->id_template,
	       $objects[0]->order_index),
       'implicit point id is composed from id_template and order_index');
    is($objects[0]->position->[0], 5, 'position x');
    is($objects[0]->position->[1], 6, 'position y');
    is($objects[1]->id,
       sprintf(Math::Geometry::Construction::Point->id_template,
	       $objects[1]->order_index),
       'implicit point id is composed from id_template and order_index');
    is($objects[1]->position->[0], 7, 'position x');
    is($objects[1]->position->[1], 8, 'position y');

    my %count = ();
    foreach($construction->objects) {
	$count{$_->id} = 1;
    }
    is(scalar(keys %count), $construction->count_objects,
       'ids are unique');
}

sub objects {
    my $construction;
    my @objects;

    $construction = Math::Geometry::Construction->new;
    @objects = $construction->objects;
    is(@objects, 0, 'no objects to start with');
    @objects = $construction->points;
    is(@objects, 0, 'no points to start with');
    @objects = $construction->lines;
    is(@objects, 0, 'no lines to start with');
    @objects = $construction->circles;
    is(@objects, 0, 'no circles to start with');

    $construction->add_point(position => [0, 0], id => 'P01');
    @objects = $construction->objects;
    is(@objects, 1, 'one object');
    is($objects[0]->id, 'P01', 'this object is my point');
    @objects = $construction->points;
    is(@objects, 1, 'one point');
    is($objects[0]->id, 'P01', 'this object is my point');
    @objects = $construction->lines;
    is(@objects, 0, 'no lines');
    @objects = $construction->circles;
    is(@objects, 0, 'no circles');

    $construction = Math::Geometry::Construction->new;
    $construction->add_line(support => [[0, 0], [1, 1]], id => 'L01');
    @objects = $construction->objects;
    is(@objects, 3, 'three objects');
    is(scalar(grep { $_->id eq 'L01' } @objects), 1,
       'my line is among them');
    @objects = $construction->points;
    is(@objects, 2, 'two points');
    @objects = $construction->lines;
    is(@objects, 1, 'one line');
    is($objects[0]->id, 'L01', 'this object is my line');
    @objects = $construction->circles;
    is(@objects, 0, 'no circles');

    $construction = Math::Geometry::Construction->new;
    $construction->add_circle(support => [0, 0],
			      center  => [1, 1],
			      id      => 'C01');
    @objects = $construction->objects;
    is(@objects, 3, 'three objects');
    is(scalar(grep { $_->id eq 'C01' } @objects), 1,
       'my circle is among them');
    @objects = $construction->points;
    is(@objects, 2, 'two points');
    @objects = $construction->lines;
    is(@objects, 0, 'no lines');
    @objects = $construction->circles;
    is(@objects, 1, 'one circle');
    is($objects[0]->id, 'C01', 'this object is my circle');
}

sub root_ok {
    my ($construction, $object) = @_;
    my $root = $object->construction;

    ok(defined($root), 'construction is defined');
    isa_ok($root, 'Math::Geometry::Construction');
    ok(defined($root->object($object->id)), 'construction has object');
}

sub root {
    my $construction = Math::Geometry::Construction->new;
    my $object;

    root_ok($construction,
	    $construction->add_point(position => [0, 0]));
    root_ok($construction,
	    $construction->add_line(support => [[0, 0], [1, 2]]));
    root_ok($construction,
	    $construction->add_circle(center => [0, 0], radius => 10));
}

sub find_line {
    my $construction;
    my @points;
    my @lines;
    my $circle;

    $construction = Math::Geometry::Construction->new;

    @points = ($construction->add_point(position => [0, 1]),
	       $construction->add_point(position => [1, 2]),
	       $construction->add_point(position => [2, 3]),
	       $construction->add_point(position => [-2, 10]));

    ok(!defined($construction->find_line(support => [@points[0, 1]])),
       'no lines, line not found');

    @lines = ($construction->add_line(support => [@points[0, 1]]));
    ok(defined($construction->find_line(support => [@points[0, 1]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[1, 0]])),
       'line found in reverse order');
    ok(!defined($construction->find_line(support => [@points[1, 2]])),
       'line not found');
    ok(!defined($construction->find_line(support => [@points[2, 3]])),
       'line not found');
    ok(!defined($construction->find_line(support => [@points[3, 0]])),
       'line not found');

    push(@lines, $construction->add_line(support => [@points[2, 3]]));
    ok(defined($construction->find_line(support => [@points[0, 1]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[1, 0]])),
       'line found in reverse order');
    ok(!defined($construction->find_line(support => [@points[1, 2]])),
       'line not found');
    ok(defined($construction->find_line(support => [@points[2, 3]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[3, 2]])),
       'line found in reverse order');
    ok(!defined($construction->find_line(support => [@points[3, 0]])),
       'line not found');

    push(@points, $construction->add_derived_point
	 ('IntersectionLineLine', {input => [@lines]}));
    ok(defined($construction->find_line(support => [@points[0, 1]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[1, 0]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[0, 4]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[4, 0]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[1, 4]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[4, 1]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[2, 3]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[3, 2]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[2, 4]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[4, 2]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[3, 4]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[4, 3]])),
       'line found');
    ok(!defined($construction->find_line(support => [@points[0, 2]])),
       'line not found');
    ok(!defined($construction->find_line(support => [@points[2, 0]])),
       'line not found');
    ok(!defined($construction->find_line(support => [@points[0, 3]])),
       'line not found');
    ok(!defined($construction->find_line(support => [@points[3, 0]])),
       'line not found');
    ok(!defined($construction->find_line(support => [@points[1, 2]])),
       'line not found');
    ok(!defined($construction->find_line(support => [@points[2, 1]])),
       'line not found');
    ok(!defined($construction->find_line(support => [@points[1, 3]])),
       'line not found');
    ok(!defined($construction->find_line(support => [@points[3, 1]])),
       'line not found');

    push(@points, $construction->add_derived_point
	 ('PointOnLine', {input => [$lines[0]], quantile => 0.2}));
    ok(defined($construction->find_line(support => [@points[0, 5]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[5, 0]])),
       'line found');
    ok(!defined($construction->find_line(support => [@points[2, 5]])),
       'line not found');
    ok(!defined($construction->find_line(support => [@points[5, 2]])),
       'line not found');

    $circle = $construction->add_circle(center => [2, -1],
					radius => 10);
    push(@points, $construction->add_derived_point
	 ('IntersectionCircleLine',
	  {input => [$lines[0], $circle]},
	  {position_selector => ['indexed_position', [0]]}));
    push(@points, $construction->add_derived_point
	 ('IntersectionCircleLine',
	  {input => [$lines[0], $circle]},
	  {position_selector => ['indexed_position', [1]]}));
    ok(defined($construction->find_line(support => [@points[0, 6]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[0, 7]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[5, 6]])),
       'line found');
    ok(defined($construction->find_line(support => [@points[6, 7]])),
       'line found');
    ok(!defined($construction->find_line(support => [@points[2, 6]])),
       'line not found');
    ok(!defined($construction->find_line(support => [@points[7, 3]])),
       'line not found');
}

sub find_circle {
    my $construction;
    my @points;
    my @circles;
    my $line;

    $construction = Math::Geometry::Construction->new;

    @points = ($construction->add_point(position => [0, 1]),
	       $construction->add_point(position => [1, 2]),
	       $construction->add_point(position => [1, 2]),
	       $construction->add_point(position => [-2, 10]),
	       $construction->add_point(position => [0, 0]));

    ok(!defined($construction->find_circle(support => [@points[0, 1]])),
       'no circles, circle not found');
    @circles = ($construction->add_circle(center  => $points[0],
					  support => $points[1]));
    ok(defined($construction->find_circle(center  => $points[0],
					  support => $points[1])),
       'circle found');
    ok(!defined($construction->find_circle(center  => $points[1],
					   support => $points[0])),
       'circle not found');
    ok(!defined($construction->find_circle(center  => $points[0],
					   support => $points[2])),
       'circle not found');
    ok(!defined($construction->find_circle(center  => $points[3],
					   support => $points[1])),
       'circle not found');

    push(@circles, $construction->add_circle(center  => $points[3],
					     support => $points[4]));
    ok(defined($construction->find_circle(center  => $points[0],
					  support => $points[1])),
       'circle found');
    ok(defined($construction->find_circle(center  => $points[3],
					  support => $points[4])),
       'circle found');

    push(@points, $construction->add_derived_point
	 ('IntersectionCircleCircle',
	  {input => [@circles[0, 1]]},
	  [{position_selector => ['indexed_position', [0]]},
	   {position_selector => ['indexed_position', [1]]}]));
    ok(defined($construction->find_circle(center  => $points[0],
					  support => $points[1])),
       'circle found');
    ok(defined($construction->find_circle(center  => $points[0],
					  support => $points[5])),
       'circle found');
    ok(defined($construction->find_circle(center  => $points[0],
					  support => $points[6])),
       'circle found');
    ok(defined($construction->find_circle(center  => $points[3],
					  support => $points[5])),
       'circle found');
    ok(defined($construction->find_circle(center  => $points[3],
					  support => $points[6])),
       'circle found');
    ok(!defined($construction->find_circle(center  => $points[0],
					   support => $points[2])),
       'circle not found');
    ok(!defined($construction->find_circle(center  => $points[0],
					   support => $points[4])),
       'circle not found');
    ok(!defined($construction->find_circle(center  => $points[3],
					   support => $points[0])),
       'circle not found');
    ok(!defined($construction->find_circle(center  => $points[3],
					   support => $points[1])),
       'circle not found');
    ok(!defined($construction->find_circle(center  => $points[4],
					   support => $points[3])),
       'circle not found');

    $line = $construction->add_line(support => [[0, -1], [10, 11]]);
    push(@points, $construction->add_derived_point
	 ('IntersectionCircleLine',
	  {input => [$line, $circles[0]]},
	  [{position_selector => ['indexed_position', [0]]},
	   {position_selector => ['indexed_position', [1]]}]));
    ok(defined($construction->find_circle(center  => $points[0],
					  support => $points[1])),
       'circle found');
    ok(defined($construction->find_circle(center  => $points[0],
					  support => $points[7])),
       'circle found');
    ok(defined($construction->find_circle(center  => $points[0],
					  support => $points[8])),
       'circle found');
    ok(!defined($construction->find_circle(center  => $points[0],
					   support => $points[2])),
       'circle not found');
    ok(!defined($construction->find_circle(center  => $points[0],
					   support => $points[4])),
       'circle not found');

    # TODO: tests with center/radius circles
}

sub find_or_add {
    my $construction;
    my @points;
    my @lines;
    my @circles;

    $construction = Math::Geometry::Construction->new;

    @points = ($construction->add_point(position => [0, 0]),
	       $construction->add_point(position => [1, 2]),
	       $construction->add_point(position => [1, 2]),
	       $construction->add_point(position => [-1, -2]),
	       $construction->add_point(position => [5, 12]));

    push(@lines,
	 $construction->find_or_add_line(support => [@points[0, 1]]));
    is($lines[0]->id, 'L000000005', 'first line');
    is($construction->find_or_add_line(support => [@points[0, 1]])->id,
       $lines[0]->id,
       'find_or_add again finds');
    push(@lines,
	 $construction->find_or_add_line(support => [@points[0, 2]]));
    is($lines[1]->id, 'L000000006',
       'another line with identical coords gets added');
    is($construction->find_or_add_line(support => [@points[0, 1]])->id,
       $lines[0]->id,
       'first is still found');

    push(@circles, $construction->find_or_add_circle
	 (center  => $points[0],
	  support => $points[1]));
    is($circles[0]->id, 'C000000007', 'first circle');
    is($construction->find_or_add_circle(center  => $points[0],
					 support => $points[1])->id,
       $circles[0]->id,
       'find_or_add again finds');
    push(@circles, $construction->find_or_add_circle
	 (center  => $points[0],
	  support => $points[2]));
    is($circles[1]->id, 'C000000008',
       'another circle with identical coords gets added');
    push(@circles, $construction->find_or_add_circle
	 (center  => $points[0],
	  support => $points[3]));
    is($circles[1]->id, 'C000000008',
       'another circle with opposite support gets added');
    push(@circles, $construction->find_or_add_circle
	 (center  => $points[0],
	  support => $points[4]));
    is($circles[1]->id, 'C000000008',
       'another circle with different support coords gets added');
    is($construction->find_or_add_circle(center  => $points[0],
					 support => $points[1])->id,
       $circles[0]->id,
       'first is still found');
}

order_index;
id;
objects;
root;
find_line;
find_circle;
find_or_add;
