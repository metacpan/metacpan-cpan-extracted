#!perl -T
use strict;
use warnings;

use Test::More tests => 73;
use Test::Exception;
use Math::Geometry::Construction;

sub is_close {
    my ($value, $reference, $message, $limit) = @_;

    cmp_ok(abs($value - $reference), '<', ($limit || 1e-12), $message);
}

sub point_on_line {
    my $construction = Math::Geometry::Construction->new;

    my $line;
    my $d;
    my $dp;
    my $pos;

    $line = $construction->add_line(support => [[10, 30], [90, 90]]);
    
    $d  = $construction->add_derivate
	('PointOnLine', input => [$line], distance => 50);
    $dp = $d->create_derived_point
	(position_selector => ['indexed_position', [0]]);

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 50, 'position x');
    is_close($pos->[1], 60, 'position y');
    
    $dp = $d->create_derived_point;

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 50, 'position x');
    is_close($pos->[1], 60, 'position y');
    
    $dp = $construction->add_derived_point
	('PointOnLine',
	 {input => [$line], distance => 50},
	 {position_selector => ['indexed_position', [0]]});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 50, 'position x');
    is_close($pos->[1], 60, 'position y');
    
    $dp = $construction->add_derived_point
	('PointOnLine',
	 {input => [$line], distance => 50},
	 {});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 50, 'position x');
    is_close($pos->[1], 60, 'position y');
    
    $dp = $construction->add_derived_point
	('PointOnLine',
	 {input => [$line], distance => 50});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 50, 'position x');
    is_close($pos->[1], 60, 'position y');
    
    $dp = $construction->add_derived_point
	('PointOnLine',
	 {input => [$line], quantile => 1.5});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 130, 'position x');
    is_close($pos->[1], 120, 'position y');
    
    $dp = $construction->add_derived_point
	('PointOnLine',
	 {input => [$line], x => 90});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 90, 'position x');
    is_close($pos->[1], 90, 'position y');
    
    $dp = $construction->add_derived_point
	('PointOnLine',
	 {input => [$line], 'y' => 120});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 130, 'position x');
    is_close($pos->[1], 120, 'position y');
}

sub alternative_sources {
    my $construction = Math::Geometry::Construction->new;
    my $line;
    my $d;

    $line = $construction->add_line(support => [[1, 2], [3, 4]]);
    lives_ok(sub { $construction->add_derivate
		       ('PointOnLine', input => $line, distance => 10) },
	     'just checking');
    throws_ok(sub { $construction->add_derivate
			('PointOnLine', input => $line) },
	      qr/At least one of the attributes.*distance.*has to be/,
	      'no source dies');
    $d = $construction->add_derivate
	('PointOnLine', input => $line, distance => 10);
    is($d->distance, 10, 'distance is 10');
    foreach('quantile', 'x', 'y') {
	my $predicate = "_has_${_}";
	ok(!$d->$predicate, "$_ is clear");
    }
    $d->quantile(0.5);
    is($d->quantile, 0.5, 'quantile is 0.5');
    foreach('distance', 'x', 'y') {
	my $predicate = "_has_${_}";
	ok(!$d->$predicate, "$_ is clear");
    }
}

sub buffering {
    my $construction = Math::Geometry::Construction->new;
    my $line;
    my $dp;
    my $pos;

    $line = $construction->add_line(support => [[0, 0], [1, 0]]);
    $dp   = $construction->add_derived_point
	('PointOnLine',
	 {input => [$line], distance => 5});
    $pos  = $dp->position;
    is_close($pos->[0], 5, 'x = 5');
    is_close($pos->[1], 0, 'y = 0');
    ok($dp->is_buffered('position'), 'position is buffered');
    $dp->derivate->x(7);
    ok(!$dp->is_buffered('position'), 'position is not buffered');
    $pos = $dp->position;
    is_close($pos->[0], 7, 'x = 7');
    is_close($pos->[1], 0, 'y = 0');
}

sub register_derived_point {
    my $construction = Math::Geometry::Construction->new;
    my $line;
    my $dp;

    $line = $construction->add_line(support => [[1, 2], [3, 4]]);
    $dp = $construction->add_derived_point
	('PointOnLine',
	 {input => [$line], quantile => 0.3});

    is(scalar(grep { $_->id eq $dp->id } $line->points), 1,
       'derived point is registered');
}

point_on_line;
alternative_sources;
buffering;
register_derived_point;
