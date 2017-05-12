#!perl -T
use strict;
use warnings;

use Test::More tests => 65;
use Test::Exception;
use Math::Geometry::Construction;

sub is_close {
    my ($value, $reference, $message, $limit) = @_;

    cmp_ok(abs($value - $reference), '<', ($limit || 1e-12), $message);
}

sub is_fairly_close {
    my ($value, $reference, $message, $limit) = @_;

    cmp_ok(abs($value - $reference), '<', ($limit || 1e-6), $message);
}

sub point {
    my $construction = Math::Geometry::Construction->new;

    my $circle;
    my $d;
    my $dp;
    my $pos;
    my @templates;

    $circle = $construction->add_circle(center  => [50, 50],
					support => [50, 20]);
    
    $d  = $construction->add_derivate
	('PointOnCircle', input => [$circle], quantile => 0.5);
    $dp = $d->create_derived_point
	(position_selector => ['indexed_position', [0]]);

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 50, 'position x');
    is_close($pos->[1], 80, 'position y');

    $dp = $d->create_derived_point;

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 50, 'position x');
    is_close($pos->[1], 80, 'position y');
    
    $dp = $construction->add_derived_point
	('PointOnCircle',
	 {input => [$circle], quantile => 0.75},
	 {position_selector => ['indexed_position', [0]]});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 20, 'position x');
    is_close($pos->[1], 50, 'position y');
    
    $dp = $construction->add_derived_point
	('PointOnCircle',
	 {input => [$circle], quantile => -0.25},
	 {});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 20, 'position x');
    is_close($pos->[1], 50, 'position y');
    
    $dp = $construction->add_derived_point
	('PointOnCircle',
	 {input => [$circle], quantile => 0});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 50, 'position x');
    is_close($pos->[1], 20, 'position y');
    
    @templates =
	([1, 75.2441295442369, 33.7909308239558],
	 [-3, 45.766399758204, 79.6997748980134,
	  100 / 30, 44.2829611137354, 79.4502201413324]);

    foreach(@templates) {
	$dp = $construction->add_derived_point
	    ('PointOnCircle',
	     {input => [$circle], phi => $_->[0]});

	ok(defined($dp), 'derived point defined');
	$pos = $dp->position;
	ok(defined($pos), 'position defined');
	is_fairly_close
	    ($pos->[0], $_->[1],
	     sprintf('position based on phi = %.2f: x = %.2f',
		     $_->[0], $_->[1]));
	is_fairly_close
	    ($pos->[1], $_->[2],
	     sprintf('position based on phi = %.2f: y = %.2f',
		     $_->[0], $_->[2]));
    }

    @templates =
	([100, 44.2829611137354, 79.4502201413324],
	 [-200, 38.7754630828634, 22.1789689084707]);

    foreach(@templates) {
	$dp = $construction->add_derived_point
	    ('PointOnCircle',
	     {input => [$circle], distance => $_->[0]});

	ok(defined($dp), 'derived point defined');
	$pos = $dp->position;
	ok(defined($pos), 'position defined');
	is_fairly_close
	    ($pos->[0], $_->[1],
	     sprintf('position based on distance = %.2f: x = %.2f',
		     $_->[0], $_->[1]));
	is_fairly_close
	    ($pos->[1], $_->[2],
	     sprintf('position based on distance = %.2f: y = %.2f',
		     $_->[0], $_->[2]));
    }
}

sub alternative_sources {
    my $construction = Math::Geometry::Construction->new;
    my $circle;
    my $d;

    $circle = $construction->add_circle(center  => [50, 50],
					support => [50, 20]);
    lives_ok(sub { $construction->add_derivate
		       ('PointOnCircle',
			input => $circle,
			distance => 10)
	     },
	     'just checking');
    throws_ok(sub { $construction->add_derivate
			('PointOnCircle', input => $circle) },
	      qr/At least one of the attributes.*distance.*has to be/,
	      'no source dies');
    $d = $construction->add_derivate
	('PointOnCircle', input => $circle, distance => 10);
    is($d->distance, 10, 'distance is 10');
    foreach('quantile', 'phi') {
	my $predicate = "_has_${_}";
	ok(!$d->$predicate, "$_ is clear");
    }
    $d->quantile(0.5);
    is($d->quantile, 0.5, 'quantile is 0.5');
    foreach('distance', 'phi') {
	my $predicate = "_has_${_}";
	ok(!$d->$predicate, "$_ is clear");
    }
}

sub buffering {
    my $construction = Math::Geometry::Construction->new;
    my $circle;
    my $dp;
    my $pos;

    $circle = $construction->add_circle(center  => [0, 0],
					support => [5, 0]);
    $dp     = $construction->add_derived_point
	('PointOnCircle',
	 {input => [$circle], quantile => 0.5});
    $pos  = $dp->position;
    is_close($pos->[0], -5, 'x = -5');
    is_close($pos->[1], 0, 'y = 0');
    ok($dp->is_buffered('position'), 'position is buffered');
    $dp->derivate->phi(0);
    ok(!$dp->is_buffered('position'), 'position is not buffered');
    $pos = $dp->position;
    is_close($pos->[0], 5, 'x = 5');
    is_close($pos->[1], 0, 'y = 0');
}

point;
alternative_sources;
buffering;
