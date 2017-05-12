#!perl -T
use strict;
use warnings;

use Test::More tests => 24;
use Test::Exception;
use Math::Geometry::Construction::Vector;
use Math::Vector::Real;
use Math::VectorReal;

sub construction {
    my $vector;
    my $value;
    my @template;

    @template = ([ {vector => [3, 5]}, [3, 5] ],
		 [ {vector => V(4, 6)}, [4, 6] ],
		 [ {vector => vector(5, 7, 1)}, [5, 7] ]);

    foreach(@template) {
	$vector = Math::Geometry::Construction::Vector->new(%{$_->[0]});
	ok(defined($vector), 'vector is defined');
	isa_ok($vector, 'Math::Geometry::Construction::Vector');
	$value = $vector->value;
	ok(defined($value), 'value is defined');
	isa_ok($value, 'Math::Vector::Real');
	is($value->[0], $_->[1]->[0], 'x = '.$_->[1]->[0]);
	is($value->[1], $_->[1]->[1], 'y = '.$_->[1]->[1]);
    }
}

sub alternative_sources {
    my $vector;
    my $value;

    lives_ok(sub { Math::Geometry::Construction::Vector->new
		       (vector => [1, 2]);
	     },
	     'just checking');

    throws_ok(sub { Math::Geometry::Construction::Vector->new },
	      qr/At least one of the attributes.*vector.*has to be/,
	      'value_source is mandatory');

    $vector = Math::Geometry::Construction::Vector->new
	(vector => [1, 2]);
    $value  = $vector->value;
    is($value->[0], 1, 'x = 1');
    is($value->[1], 2, 'y = 2');
    foreach('point', 'point_point') {
	my $predicate = "_has_${_}";
	ok(!$vector->$predicate, "$_ is clear");
    }
    # more cannot be checked without Point or Line
}

construction;
alternative_sources;
