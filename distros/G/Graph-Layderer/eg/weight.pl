#!/usr/bin/perl -w
# (c) <hossman_cpan@fucit.org>

use strict;
use diagnostics;
use warnings;

use lib qw (../blib/lib);

use Graph::Undirected;
use Imager;
use Graph::Layouter::Spring;
use Graph::Renderer::Imager;

my $g = Graph::Undirected->new();
# evenly weighted triangle 1->2->3->1
$g->add_weighted_edge(1 , 10 , 2);
$g->add_weighted_edge(2 , 10 , 3);
$g->add_weighted_edge(3 , 10 , 1);
# put 4 in the middle, heavily drawn to 1
$g->add_weighted_edge(1 , 200, 4);
$g->add_weighted_edge(2 , 20 , 4);
$g->add_weighted_edge(3 , 20 , 4);
my $img = Imager->new(xsize => 800, ysize => 600, channels => 4);
$img->box(color => Imager::Color->new(0xff, 0xff, 0xff),
xmin => 0, ymin => 0, xmax => 800, ymax => 600, filled => 1);
Graph::Layouter::Spring::layout($g);
Graph::Renderer::Imager::render($g, $img);
$img->write(file=>'z.png');
