#!/usr/bin/perl
use strict;
use warnings;

use Math::Geometry::Construction;
use Math::Geometry::Construction::Derivate::PointOnLine;
use Math::Geometry::Construction::Derivate::TranslatedPoint;
use Math::VectorReal;
use SVG::Rasterize;
use LaTeX::TikZ;

my $POINTS_PER_CM = 100;

my $construction = Math::Geometry::Construction->new
    (background => 'white');

sub circle {
    my $p01 = $construction->add_point('x' => 200, 'y' => 150);
    my $p02 = $construction->add_point('x' => 200, 'y' => 50);
    my $c1  = $construction->add_circle(center       => $p01,
					support      => $p02,
					partial_draw => 1);


    my $p03 = $construction->add_point('x' => 190, 'y' => 40);
    my $p04 = $construction->add_point('x' => 310, 'y' => 160);

    my $l1 = $construction->add_line(support => [$p03, $p04],
				     extend  => 30);

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

    my $p07 = $construction->add_point('x' => 600, 'y' => 150);
    my $p08 = $construction->add_point('x' => 600, 'y' => 250);
    my $c2  = $construction->add_circle(center       => $p07,
					support      => $p08,
					partial_draw => 1,
					extend       => [20, 20]);

    my $p09 = $construction->add_point('x' => 570, 'y' => 40);
    my $p10 = $construction->add_point('x' => 710, 'y' => 160);

    my $l2 = $construction->add_line(support => [$p09, $p10],
				     extend  => 30);


    my $i2 = $construction->add_derivate('IntersectionCircleLine',
					 input => [$l2, $c2]);
    my $p11 = $i2->create_derived_point
	(position_selector => ['indexed_position', [0]],
	 label             => 'A',
	 label_offset_x    => 5,
	 label_offset_y    => -5);
    my $p12 = $i2->create_derived_point
	(position_selector => ['indexed_position', [1]],
	 label             => 'B',
	 label_offset_x    => 5,
	 label_offset_y    => -5);

=for later

=cut

}

circle;

my $svg = $construction->as_svg(width => 800, height => 300,
				viewBox             => "0 0 800 300");
    
#print $svg->xmlify, "\n";
    
my $rasterize = SVG::Rasterize->new();
$rasterize->rasterize(svg => $svg);
$rasterize->write(type => 'png', file_name => 'construction.png');

my $tikz = $construction->draw('TikZ',
			       width     => 8,
			       height    => 3,
			       view_box  => [0, 0, 800, 300],
			       transform => [1 / $POINTS_PER_CM, 0,
					     0, 1 / $POINTS_PER_CM,
					     0, 0],
			       svg_mode  => 1);
my (undef, undef, $body) = Tikz->formatter->render($tikz);
my $string = sprintf("%s\n", join("\n", @$body));
#print $string;

open(TIKZ, '>', 'construction.tex');
print TIKZ <<END_OF_TEX;
\\documentclass{article}
\\usepackage{tikz}
\\begin{document}
$string\\end{document}
END_OF_TEX
close(TIKZ);
