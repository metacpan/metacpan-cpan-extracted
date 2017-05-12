#!perl -T
use strict;
use warnings;

use Test::More tests => 46;
use Test::Exception;
use Math::Geometry::Construction;
use Math::Vector::Real;

sub is_close {
    my ($value, $reference, $message, $limit) = @_;

    cmp_ok(abs($value - $reference), '<', ($limit || 1e-12), $message);
}

sub fixed_point {
    my $construction = Math::Geometry::Construction->new;
    my @points;
    my @lines;
    my @circles;

    @points = ($construction->add_point(position => [2, -1]),
	       $construction->add_point(position => [4, -1]),
	       $construction->add_point(position => [3,  5]),
	       $construction->add_point(position => [3,  7]));

    @lines = ($construction->add_line(support => [@points[0, 1]]),
	      $construction->add_line(support => [@points[2, 3]]));

    push(@points, $construction->add_derived_point
	 ('IntersectionLineLine',
	  {input => [@lines[0, 1]]}));

    is($points[4]->position->[0],  3, 'initial x');
    is($points[4]->position->[1], -1, 'initial y');

    $points[1]->position(V(4, -3));
    is($points[4]->position->[0],  3, 'updated x');
    is($points[4]->position->[1], -2, 'updated y');

    push(@points, $construction->add_derived_point
	 ('TranslatedPoint',
	  {input => [$points[0]], translator => [1, 2]}));
    is($points[5]->position->[0], 3, 'initial x');
    is($points[5]->position->[1], 1, 'initial y');
    $points[0]->position(V(12, -4));
    is($points[5]->position->[0], 13, 'updated x');
    is($points[5]->position->[1], -2, 'updated y');

    # changing position selection
    @points = ($construction->add_point(position => [0, 0]),
	       $construction->add_point(position => [4, 7]),
	       $construction->add_point(position => [4, -1]),
	       $construction->add_point(position => [4, 2]));
    
    @circles = ($construction->add_circle(center => $points[0],
					  radius => 5));
    @lines = ($construction->add_line(support => [@points[1, 2]]));

    push(@points, $construction->add_derived_point
	 ('IntersectionCircleLine',
	  {input => [$circles[0], $lines[0]]},
	  {position_selector => ['close_position', [$points[3]]]}));
    is($points[4]->position->[0], 4, 'initial x');
    is($points[4]->position->[1], 3, 'initial y');
    $points[0]->position(V(0, 4));
    is($points[4]->position->[0], 4, 'updated x');
    is($points[4]->position->[1], 1, 'updated y');

    # chained dependency
    @points = ($construction->add_point(position => [1, -4]));
    push(@points,
	 $construction->add_derived_point
	 ('TranslatedPoint',
	  {input => [$points[0]], translator => [-1, 2]}),
	 $construction->add_derived_point
	 ('TranslatedPoint',
	  {input => [$points[0]], translator => [3, 5]}),
	 $construction->add_derived_point
	 ('TranslatedPoint',
	  {input => [$points[0]], translator => [-4, 5]}));
    @circles = ($construction->add_circle(center => $points[1],
					  radius => 5));
    @lines = ($construction->add_line(support => [@points[2, 3]]));

    push(@points, $construction->add_derived_point
	 ('IntersectionCircleLine',
	  {input => [$circles[0], $lines[0]]},
	  {position_selector => ['extreme_position', [[1, 0]]]}));
    is($points[4]->position->[0], 4, 'initial x');
    is($points[4]->position->[1], 1, 'initial y');
    $points[0]->position(V(-10, -3));
    is($points[4]->position->[0], -7, 'updated x');
    is($points[4]->position->[1], 2, 'updated y');
}

sub translator {
    my $construction = Math::Geometry::Construction->new;
    my @points;

    @points = ($construction->add_point(position => [5, -8]));
    push(@points,
	 $construction->add_derived_point
	 ('TranslatedPoint',
	  {input => [$points[0]], translator => [-3, 7]}),
	 $construction->add_derived_point
	 ('TranslatedPoint',
	  {input => [$points[0]], translator => [10, -5]}));
    is($points[1]->position->[0], 2, 'initial x');
    is($points[1]->position->[1], -1, 'initial y');
    is($points[2]->position->[0], 15, 'initial x');
    is($points[2]->position->[1], -13, 'initial y');

    $points[1]->derivate->translator(V(-5, 2));
    is($points[1]->position->[0], 0, 'updated x');
    is($points[1]->position->[1], -6, 'updated y');
    is($points[2]->position->[0], 15, 'updated x');
    is($points[2]->position->[1], -13, 'updated y');
}

sub point_on_line {
    my $construction = Math::Geometry::Construction->new;
    my @points;
    my @lines;

    @points = ($construction->add_point(position => [5, -8]),
	       $construction->add_point(position => [15, -12]));
    @lines  = ($construction->add_line(support => [@points[0, 1]]));
    push(@points,
	 $construction->add_derived_point
	 ('PointOnLine',
	  {input => [$lines[0]], quantile => 0.5}));
    push(@points,
	 $construction->add_derived_point
	 ('TranslatedPoint',
	  {input => [$points[2]], translator => [3, -1]}));
    is($points[2]->position->[0], 10, 'initial x');
    is($points[2]->position->[1], -10, 'initial y');
    is($points[3]->position->[0], 13, 'initial x');
    is($points[3]->position->[1], -11, 'initial y');

    $points[2]->derivate->quantile(0.75);
    is($points[2]->position->[0], 12.5, 'updated x');
    is($points[2]->position->[1], -11, 'updated y');
    is($points[3]->position->[0], 15.5, 'updated x');
    is($points[3]->position->[1], -12, 'updated y');

    $points[2]->derivate->quantile(0.25);
    is($points[3]->position->[0], 10.5, 'updated x');
    is($points[3]->position->[1], -10, 'updated y');

    $points[2]->derivate->distance(0);
    is($points[2]->position->[0], 5, 'updated x');
    is($points[2]->position->[1], -8, 'updated y');
    is($points[3]->position->[0], 8, 'updated x');
    is($points[3]->position->[1], -9, 'updated y');

    $points[2]->derivate->x(10);
    is($points[2]->position->[0], 10, 'updated x');
    is($points[2]->position->[1], -10, 'updated y');
    is($points[3]->position->[0], 13, 'updated x');
    is($points[3]->position->[1], -11, 'updated y');

    $points[2]->derivate->y(-11);
    is($points[2]->position->[0], 12.5, 'updated x');
    is($points[2]->position->[1], -11, 'updated y');
    is($points[3]->position->[0], 15.5, 'updated x');
    is($points[3]->position->[1], -12, 'updated y');
}

fixed_point;
translator;
point_on_line;
