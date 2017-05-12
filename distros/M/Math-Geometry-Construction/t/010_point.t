#!perl -T
use strict;
use warnings;

use Test::More tests => 112;
use Test::Exception;
use Test::Warn;
use Math::Geometry::Construction;
use Math::VectorReal;
use Math::Vector::Real;

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

sub constructs_ok {
    my ($construction, $args, $x, $y) = @_;
    my $point;

    warning_is { $point = $construction->add_point(%$args) } undef,
        'no warnings in constructor';

    ok(defined($point), 'point is defined');
    isa_ok($point, 'Math::Geometry::Construction::Point');
    position_ok($point->position, $x, $y);

    return $point;
}

sub construction {
    my $construction = Math::Geometry::Construction->new;
    my $point;
    my @template;

    @template = ([{position => [1, 2]}, [1, 2]],
		 [{position => [3, 4, 5]}, [3, 4]],
		 [{position => V(6, 7)}, [6, 7]],
		 [{position => vector(8, 9, 10)}, [8, 9]],
		 [{x => 11, 'y' => 12}, [11, 12]],
		 [{x => 13, 'y' => 14, z => 15}, [13, 14]]);

    foreach(@template) {
	constructs_ok($construction, $_->[0], @{$_->[1]});
    }

    $point = $construction->add_point(position => [0, 0]);
    ok(!$point->hidden, 'point not hidden by default');
    $point->hidden(1);
    ok($point->hidden, 'point can be hidden');
    $point = $construction->add_point(position => [0, 0],
				      hidden   => 1);
    ok($point->hidden, 'point can be hidden at startup');
}

sub modify_position {
    my $construction = Math::Geometry::Construction->new;
    my $point        = $construction->add_point(position => [0, 0]);
    my @template;
    
    position_ok($point->position, 0, 0);
    
    @template = ([[1, 2], [1, 2]],
		 [[3, 4, 5], [3, 4]],
		 [V(6, 7), [6, 7]],
		 [vector(8, 9, 10), [8, 9]]);

    foreach(@template) {
	lives_ok(sub { $point->position($_->[0]) },
	     'point lives through position change');
	position_ok($point->position, @{$_->[1]});
    }
}

sub defaults {
    my $construction = Math::Geometry::Construction->new;
    my $point;

    $point = $construction->add_point(position => [0, 0]);
    is($point->size, 6, 'default point size 6');
    is($point->radius, 3, 'default radius 3');

    $construction->point_size(7.5);
    $point = $construction->add_point(position => [0, 0]);
    is($point->size, 7.5, 'default point size 7.5');
    is($point->radius, 3.75, 'default radius 3.75');
    $point->size(12);
    is($point->size, 12, 'adjusted point size 12');
    is($point->radius, 6, 'adjusted radius size 6');

    $point = $construction->add_point(position => [0, 0], size => 13.35);
    is($point->size, 13.35, 'constructed point size 13.35');
    is($point->radius, 6.675, 'constructed radius size 6.675');
}

sub vector_and_point {
    my $construction = Math::Geometry::Construction->new;
    my $p;
    my $vector;
    my $value;
    my @template;

    $p = $construction->add_point(position => [1, 2]);

    @template = ([$p, [1, 2]]);

    foreach(@template) {
	$vector = Math::Geometry::Construction::Vector->new
	    (point => $_->[0]);
	ok(defined($vector), 'vector is defined');
	isa_ok($vector, 'Math::Geometry::Construction::Vector');
	$value = $vector->value;
	ok(defined($value), 'value is defined');
	isa_ok($value, 'Math::Vector::Real');
	is($value->[0], $_->[1]->[0], 'x = '.$_->[1]->[0]);
	is($value->[1], $_->[1]->[1], 'y = '.$_->[1]->[1]);
    }

    constructs_ok($construction, {position => $p}, 1, 2);

    $vector = Math::Geometry::Construction::Vector->new
	(vector => [3, 4]);
    $value  = $vector->value;
    is($value->[0], 3, 'x = 3');
    is($value->[1], 4, 'y = 4');
    foreach('point', 'point_point') {
	my $predicate = "_has_${_}";
	ok(!$vector->$predicate, "$_ is clear");
    }

    $vector->point($p);
    $value  = $vector->value;
    is($value->[0], 1, 'x = 1');
    is($value->[1], 2, 'y = 2');
    foreach('vector', 'point_point') {
	my $predicate = "_has_${_}";
	ok(!$vector->$predicate, "$_ is clear");
    }
}

sub draw {
    my $construction;

    $construction = Math::Geometry::Construction->new;
    $construction->add_point(position => [0, 0]);

    lives_ok(sub { $construction->as_svg(width => 800, height => 300) },
	     'construction with point lives through as_svg');
    lives_ok(sub { $construction->as_tikz(width => 800, height => 300) },
	     'construction with point lives through as_tikz');
}

construction;
modify_position;
defaults;
vector_and_point;
draw;
