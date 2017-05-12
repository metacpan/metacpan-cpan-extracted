#!/usr/bin/perl
use strict;
use warnings;

use Math::Geometry::Construction;
use SVG::Rasterize;

sub triangle {
    my ($construction) = @_;

    my $a = $construction->add_point(position => [100, 100],
				     id       => 'A');
    my $b = $construction->add_derived_point
	('TranslatedPoint',
	 {input => [$a], translator => [800, 100]},
	 {id => 'B'});
    my $c = $construction->add_derived_point
	('TranslatedPoint',
	 {input => [$a], translator => [200, 600]},
	 {id => 'C'});

    my $ab = $construction->add_line(support => [$a, $b], id => 'AB');
    my $bc = $construction->add_line(support => [$b, $c], id => 'BC');
    my $ca = $construction->add_line(support => [$c, $a], id => 'CA');
}

sub angle_bisector {
    my ($construction, $a, $b, $c, $style) = @_;

    my $c1 = $construction->find_or_add_circle(center  => $b,
					       support => $a,
					       style   => {%$style});
    my $ba = $construction->find_or_add_line(support => [$b, $a]);
    my $bc = $construction->find_or_add_line(support => [$b, $c]);
    my $p1 = $construction->add_derived_point
	('IntersectionCircleLine',
	 {input => [$c1, $bc]},
	 {position_selector => ['extreme_position', [$bc->parallel]],
	  style             => {%$style}});
    
    my $c2 = $construction->find_or_add_circle(center  => $a,
					       support => $p1,
					       style   => {%$style});
    my $c3 = $construction->find_or_add_circle(center  => $p1,
					       support => $a,
					       style   => {%$style});
    return $construction->add_derived_point
	('IntersectionCircleCircle',
	 {input => [$c2, $c3]},
	 {position_selector => ['distant_position', [$b->position]],
	  style             => {%$style}});
}

sub circles1 {
    my ($construction) = @_;
    my $style;
    my $a = $construction->object('A');
    my $b = $construction->object('B');
    my $c = $construction->object('C');

    $style = {stroke => 'blue'};
    my $absap = angle_bisector($construction, $c, $a, $b, $style);
    my $absa  = $construction->add_line(support => [$a, $absap],
					style   => {%$style});
    my $absbp = angle_bisector($construction, $a, $b, $c, $style);
    my $absb  = $construction->add_line(support => [$b, $absbp],
					style   => {%$style});
    my $abscp = angle_bisector($construction, $b, $c, $a, $style);
    my $absc  = $construction->add_line(support => [$c, $abscp],
					style   => {%$style});

    my $center = $construction->add_derived_point
	('IntersectionLineLine',
	 {input => [$absa, $absb]},
	 {style => {%$style}});

    $style = {stroke => 'green'};
    my $absah2p = angle_bisector($construction, $center, $a, $b, $style);
    my $absah2  = $construction->add_line(support => [$a, $absah2p],
					  style   => {%$style});
    my $absbh1p = angle_bisector($construction, $a, $b, $center, $style);
    my $absbh1  = $construction->add_line(support => [$b, $absbh1p],
					  style   => {%$style});
}

my $construction = Math::Geometry::Construction->new;

triangle($construction);
circles1($construction);

my $svg = $construction->as_svg(width      => 1000,
				height     => 1000,
				transform  => [1, 0, 0, -1, 0, 1000],
				background => 'white');

my $rasterize = SVG::Rasterize->new();
$rasterize->rasterize(svg => $svg);
$rasterize->write(type => 'png', file_name => 'malfatti.png');
