#!perl -T
use strict;
use warnings;

use Test::More tests => 69;
use Math::Geometry::Construction;
use Test::Exception;

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

sub line_line {
    my $construction = Math::Geometry::Construction->new;
    my @lines;
    my $d;
    my $dp;

    @lines = ($construction->add_line(support => [[10, 30], [30, 30]]),
	      $construction->add_line(support => [[20, 10], [20, 40]]));
    
    $d  = $construction->add_derivate
	('IntersectionLineLine', input => [@lines]);
    $dp = $d->create_derived_point
	(position_selector => ['indexed_position', [0]]);
    derived_point_ok($dp, 20, 30);

    $dp = $d->create_derived_point;
    derived_point_ok($dp, 20, 30);

    $dp = $construction->add_derived_point
	('IntersectionLineLine',
	 {input => [@lines]},
	 {position_selector => ['indexed_position', [0]]});
    derived_point_ok($dp, 20, 30);

    $dp = $construction->add_derived_point
	('IntersectionLineLine',
	 {input => [@lines]},
	 {});
    derived_point_ok($dp, 20, 30);

    $dp = $construction->add_derived_point
	('IntersectionLineLine',
	 {input => [@lines]});
    derived_point_ok($dp, 20, 30);
}

sub id {
    my $construction = Math::Geometry::Construction->new;
    my @lines;
    my $d;
    my $dp;
    my %count;

    @lines = ($construction->add_line(support => [[10, 30], [30, 30]]),
	      $construction->add_line(support => [[20, 10], [20, 40]]));

    $d = $construction->add_derivate
	('IntersectionLineLine', input => [@lines]);
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
	('IntersectionLineLine', {input => [@lines]});
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
	('IntersectionLineLine',
	 {input => [$construction->add_line(support => [[1, 2], [3, 4]]),
		    $construction->add_line(support => [[5, 6], [7, 8]])]});

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
    my @lines;
    my $d;

    @lines = ($construction->add_line(support => [[10, 30], [30, 30]]),
	      $construction->add_line(support => [[20, 10], [20, 40]]));
    
    $d = $construction->add_derivate
	('IntersectionLineLine', input => [@lines]);
    is($d->count_input, 2, 'count_input works and delivers 2');
    @lines = $d->input;
    foreach(@lines) {
	isa_ok($_, 'Math::Geometry::Construction::Line');
    }
    foreach(0, 1) {
	isa_ok($d->single_input($_),
	       'Math::Geometry::Construction::Line');
    }

    @template = ([$lines[0]],
		 $lines[0],
		 [$lines[0], $lines[1]->single_support(0)]);
    
    foreach(@template) {
	throws_ok(sub { $construction->add_derivate
			('IntersectionLineLine', input => $_); },
		  qr/type constraint/,
		  'LineLine type constraint');
    }
}

sub register_derived_point {
    my $construction = Math::Geometry::Construction->new;
    my @lines;
    my $dp;

    @lines = ($construction->add_line(support => [[1, 2], [3, 4]]),
	      $construction->add_line(support => [[5, 6], [7, 8]]));
    $dp = $construction->add_derived_point
	('IntersectionLineLine',
	 {input => [@lines]});

    is(scalar(grep { $_->id eq $dp->id } $lines[0]->points), 1,
       'derived point is registered');
    is(scalar(grep { $_->id eq $dp->id } $lines[1]->points), 1,
       'derived point is registered');
}

sub overloading {
    my $construction = Math::Geometry::Construction->new;

    my @lines;
    my $dp;
    my $pos;

    @lines = ($construction->add_line(support => [[10, 30], [30, 30]]),
	      $construction->add_line(support => [[20, 10], [20, 40]]));
    
    $dp = $lines[0] x $lines[1];
    derived_point_ok($dp, 20, 30);
        
    $dp = $lines[1] x $lines[0];
    derived_point_ok($dp, 20, 30);
}

line_line;
id;
input;
register_derived_point;
overloading;
