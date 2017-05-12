#!perl -T
use strict;
use warnings;

use Test::More tests => 133;
use Test::Exception;
use Test::Warn;
use Math::Geometry::Construction;
use Math::Vector::Real;
use Math::VectorReal;

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

sub support_ok {
    my ($circle, $pos) = @_;
    my $center  = $circle->center;
    my $support = $circle->support;

    ok(defined($center), 'center point defined');
    isa_ok($center, 'Math::Geometry::Construction::Point');
    position_ok($center->position, @{$pos->[0]});
    if($pos->[1]) {
	ok(defined($support), 'support point defined');
	isa_ok($support, 'Math::Geometry::Construction::Point');
	position_ok($support->position, @{$pos->[1]});
    }
}

sub constructs_ok {
    my ($construction, $args, $pos) = @_;
    my $circle;

    warning_is { $circle = $construction->add_circle(%$args) } undef,
        'no warnings in constructor';

    ok(defined($circle), 'circle is defined');
    isa_ok($circle, 'Math::Geometry::Construction::Circle');
    support_ok($circle, $pos);

    if($args->{radius}) {
	is_close($circle->radius, $args->{radius},
		 'radius is '.$args->{radius});
    }
    else {
	my $radius = sqrt(($pos->[1]->[0] - $pos->[0]->[0])**2 +
			  ($pos->[1]->[1] - $pos->[0]->[1])**2);
	is_close($circle->radius, $radius, "radius is $radius");
    }

    return $circle;
}

sub construction {
    my $construction = Math::Geometry::Construction->new;
    my $point;
    my $circle;
    my @template;

    $point = $construction->add_point(position => [14, 15]);
    @template = ([{center  => [1, 2],
		   support => [3, 4]},
		  [[1, 2], [3, 4]]],
		 [{center  => V(5, 6),
		   support => [7, 8]},
		  [[5, 6], [7, 8]]],
		 [{center  => V(9, 10),
		   support => vector(11, 12, 13)},
		  [[9, 10], [11, 12]]],
		 [{center  => $point,
		   support => [16, 17]},
		  [[14, 15], [16, 17]]],
		 [{center => [18, 19],
		   radius => 20},
		  [[18, 19]]]);

    foreach(@template) {
	constructs_ok($construction, $_->[0], $_->[1]);
    }

    dies_ok(sub { $construction->add_circle },
	    'dies without center');
    dies_ok(sub { $construction->add_circle(center => [1, 2]) },
	    'dies without support');

    $circle = $construction->add_circle(center  => [1, 2],
					support => [3, 4]);
    ok(!$circle->hidden, 'circle not hidden by default');
    $circle->hidden(1);
    ok($circle->hidden, 'circle can be hidden');
    $circle = $construction->add_circle(center  => [1, 2],
					support => [3, 4],
					hidden  => 1);
    ok($circle->hidden, 'circle can be hidden at startup');
}

sub modify_positions {
    my $construction = Math::Geometry::Construction->new;
    my $point;
    my $circle;

    $circle = $construction->add_circle(center  => [1, 2],
					support => [3, 4]);

    $point  = $construction->add_point(position => [5, 6]);
    dies_ok(sub { $circle->center($point) },
	    'center is readonly');
    lives_ok(sub { $circle->center->position([7, 8]) },
	     'center position can be changed');
    position_ok($circle->center->position, 7, 8);
    lives_ok(sub { $circle->center->position($point) },
	     'center position gets coerced');
    position_ok($circle->center->position, 5, 6);

    dies_ok(sub { $circle->support($point) },
	    'support is readonly');
    lives_ok(sub { $circle->support->position([9, 10]) },
	     'support position can be changed');
    position_ok($circle->support->position, 9, 10);
    lives_ok(sub { $circle->support->position($point) },
	     'support position gets coerced');
    position_ok($circle->support->position, 5, 6);

    throws_ok(sub { $circle->radius(11) },
	      qr/Refusing to set radius on circle .* without fixed radius/,
	      'radius cannot be set on normal circle');

    $circle = $construction->add_circle(center => [12, 13],
					radius => 14);
    is_close($circle->radius, 14, "radius is 14");
    $circle->center->position([15, 16]);
    is_close($circle->radius, 14, "radius stays 14");

    lives_ok(sub { $circle->radius(17) },
	     'radius can be set on fixed radius circle');
    is_close($circle->radius, 17, "radius is 17");
    $circle->center->position([18, 19]);
    is_close($circle->radius, 17, "radius stays 17");
}

sub identify_points {
    my $construction = Math::Geometry::Construction->new;
    my @points;
    my $circle;

    push(@points, $construction->add_point(position => [1, 2]));
    push(@points, $construction->add_point(position => [3, 4]));
    $circle = $construction->add_circle(center  => $points[0],
					support => $points[1]);

    is($circle->center->id, $points[0]->id,
       'center point has been used');
    is($circle->support->id, $points[1]->id,
       'support point has been used');

    is_deeply([map { $_->id } $circle->points], [$points[1]->id],
	      'points retrieves the support point');
}

sub defaults {
    my $construction = Math::Geometry::Construction->new;
    my $circle;

    $circle = $construction->add_circle(center  => [1, 2],
					support => [3, 4]);

    is($circle->partial_draw, 0, 'partial_draw off by default');
    is_close($circle->min_gap, 1.5707963267949,
	     'min_gap pi/2 by default');
    $circle->partial_draw(1);
    is($circle->partial_draw, 1, 'partial_draw can be turned on');
    $circle->min_gap(1);
    is($circle->min_gap, 1, 'min_gap can be changed');

  SKIP: {
      skip 'Not implemented, yet', 4;
      
      $construction->partial_circles(1);
      $construction->min_gap(2);
      $circle = $construction->add_circle(center  => [1, 2],
					  support => [3, 4]);
      is($circle->partial_draw, 1,
	 'partial_draw can be turned on globally');
      is($circle->min_gap, 2, 'min_gap can be changed globally');

      $construction->partial_circles(0);
      $construction->min_gap(3);
      is($circle->partial_draw, 0, 'partial_draw is volatile');
      is($circle->min_gap, 3, 'min_gap is volatile');
    };
}

sub draw {
    my $construction;

    $construction = Math::Geometry::Construction->new;
    $construction->add_circle(center  => [1, 2],
			      support => [3, 4]);

    lives_ok(sub { $construction->as_svg(width => 800, height => 300) },
	     'construction with circle lives through as_svg');
    lives_ok(sub { $construction->as_tikz(width => 800, height => 300) },
	     'construction with circle lives through as_tikz');
}

construction;
modify_positions;
identify_points;
defaults;
draw;
