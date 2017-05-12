#!/usr/bin/perl
use strict;
use warnings;

use Math::Geometry::Construction;
use Math::Geometry::Construction::Derivate::PointOnLine;
use Math::Geometry::Construction::Derivate::TranslatedPoint;
use Math::VectorReal;
use SVG::Rasterize;
use LaTeX::TikZ;

my $construction = Math::Geometry::Construction->new
    (background => 'white');

sub line {
    my $p1 = $construction->add_point('x' => 500, 'y' => 100, hidden => 1);
    my $p2 = $construction->add_point(position => vector(700, 200, 0),
				      style    => {stroke => 'none',
						   fill   => 'blue',
						   'fill-opacity' => 0.5});
    my $l1 = $construction->add_line
	(extend  => 50,
	 support => [$p1, $p2],
	 style   => {stroke => [218, 112, 214]});
}

sub intersection {
    my $p1 = $construction->add_point('x' => 100, 'y' => 150);
    my $p2 = $construction->add_point('x' => 120, 'y' => 150);
    my $p3 = $construction->add_point('x' => 200, 'y' => 50);
    my $p4 = $construction->add_point
	('x' => 200, 'y' => 250,
	 label          => "P_4",
	 label_offset_x => 7,
	 label_offset_y => 10,
	 label_style    => {'font-family' => 'Helvetica'});

    my $l1 = $construction->add_line(extend         => 10,
				     label          => 'g',
				     label_offset_y => 13,
				     support        => [$p1, $p2]);
    my $l2 = $construction->add_line(support => [$p3, $p4]);

    my $i1 = $construction->add_derivate('IntersectionLineLine',
					 input => [$l1, $l2]);
    my $p5 = $i1->create_derived_point
	(position_selector => ['indexed_position', [0]],
	 label             => 'S',
	 label_offset_x    => 5,
	 label_offset_y    => -5);
}

sub circle {
    my $p01 = $construction->add_point('x' => 190, 'y' => 200);
    my $p02 = $construction->add_point('x' => 190, 'y' => 170, hidden => 1);
    my $c1  = $construction->add_circle(center  => $p01,
					support => $p02);

    my $p03 = $construction->add_point('x' => 200, 'y' => 50, hidden => 1);
    my $p04 = $construction->add_point('x' => 200, 'y' => 60, hidden => 1);

    my $l1 = $construction->add_line(hidden  => 1,
				     support => [$p03, $p04]);

    my $i1 = $construction->add_derivate('IntersectionCircleLine',
					 input => [$l1, $c1]);
    my $p05 = $i1->create_derived_point
	(position_selector => ['indexed_position', [0]],
	 label             => 'T',
	 label_offset_x    => 5,
	 label_offset_y    => -5);
    my $p06 = $i1->create_derived_point
	(position_selector => ['indexed_position', [1]],
	 label             => 'U',
	 label_offset_x    => 5,
	 label_offset_y    => -5);

    my $p07 = $construction->add_point('x' => 350, 'y' => 200);
    my $p08 = $construction->add_point('x' => 350, 'y' => 240, hidden => 1);
    my $c2  = $construction->add_circle(center  => $p07,
					support => $p08);
    my $p09 = $construction->add_point('x' => 360, 'y' => 220);
    my $p10 = $construction->add_point('x' => 360, 'y' => 270, hidden => 1);
    my $c3  = $construction->add_circle(center  => $p09,
					support => $p10);

    my $i2 = $construction->add_derivate('IntersectionCircleCircle',
					 input => [$c2, $c3]);
    my $p11 = $i2->create_derived_point
	(position_selector => ['indexed_position', [0]]);
    my $p12 = $i2->create_derived_point
	(position_selector => ['indexed_position', [1]]);
}

sub derivates {
    my $p01 = $construction->add_point('x' => 450, 'y' => 200);
    my $p02 = $construction->add_point('x' => 550, 'y' => 220);
    my $l01 = $construction->add_line(support => [$p01, $p02]);

    my $d01 = $construction->add_derivate('PointOnLine',
					  input    => [$l01],
					  quantile => 0.3);
    my $p03 = $d01->create_derived_point
	(position_selector => ['indexed_position', [0]]);
    my $d02 = $construction->add_derivate('PointOnLine',
					  input => [$l01],
					  x     => 540);
    my $p04 = $d02->create_derived_point
	(position_selector => ['indexed_position', [0]],
	 style             => {fill => 'blue'});

    my $d03 = $construction->add_derivate
	('TranslatedPoint',
	 input      => [$p04],
	 translator => vector(0, -30, 0));
    my $p05 = $d03->create_derived_point
	(position_selector => ['indexed_position', [0]]);
    my $c01 = $construction->add_circle(center  => $p05,
					support => $p04);
}

sub convenience {
    my $p01 = $construction->add_point('x' => 700, 'y' => 100);
    my $p02 = $construction->add_derived_point
	('TranslatedPoint', {input      => [$p01],
			     translator => vector(0, -10, 0)});
}

#line;
#intersection;
circle;
#derivates;
#convenience;

# width/height are on purpose not proportional to those of the
# construction; this is to show how you can hand over SVG
# parameters
my $svg = $construction->as_svg(width => 600, height => 450,
				viewBox             => "0 0 800 300",
				preserveAspectRatio => "xMinYMid",
				'font-family'       => 'Times');
    
print $svg->xmlify, "\n";
    
my $rasterize = SVG::Rasterize->new();
$rasterize->rasterize(svg => $svg);
$rasterize->write(type => 'png', file_name => 'construction.png');

my $tikz = $construction->draw('TikZ',
			       width    => 8,
			       height   => 3,
			       view_box => [0, 0, 800, 300],
			       svg_mode => 1);
my (undef, undef, $body) = Tikz->formatter->render($tikz);
my $string = sprintf("%s\n", join("\n", @$body));
print $string;

open(TIKZ, '>', 'construction.tex');
print TIKZ <<END_OF_TEX;
\\documentclass{article}
\\usepackage{tikz}
\\begin{document}
$string\\end{document}
END_OF_TEX
close(TIKZ);
