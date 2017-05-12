#!/usr/bin/perl
use strict;
use warnings;

use Math::Geometry::Construction;

my $construction = Math::Geometry::Construction->new
    (background => 'white');
my $p1 = $construction->add_point('x' => 100, 'y' => 150, hidden => 1);
my $p2 = $construction->add_point('x' => 120, 'y' => 150, hidden => 1);
my $p3 = $construction->add_point('x' => 200, 'y' => 50);
my $p4 = $construction->add_point('x' => 200, 'y' => 250);

my $l1 = $construction->add_line(extend         => 10,
                                 label          => 'g',
				 label_offset_y => 13,
				 support        => [$p1, $p2]);
my $l2 = $construction->add_line(support => [$p3, $p4]);

my $i1 = $construction->add_derivate('IntersectionLineLine',
                                     input => [$l1, $l2]);
my $p5 = $i1->create_derived_point(label          => 'S',
                                   label_offset_x => 5,
	                           label_offset_y => -5);

my $c1 = $construction->add_circle(center => $p5, radius => 20);

# an intersection point can also be generated in one go
my $p6 = $construction->add_derived_point
    ('IntersectionCircleLine',
     {input => [$l1, $c1]},
     {position_selector => ['extreme_position', [[1, 0]]]});

print $construction->as_svg(width => 800, height => 300)->xmlify;
