#!/usr/bin/perl -w

# Copyright 2018, 2020 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use List::Util 'min';
use Math::BaseCnv 'cnv';

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;



{
  # Henry Ernest Dudeney, "Amusements in Mathematics", 1917, puzzle 243
  # "Visiting the Towns", page 70.
  # http://www.gutenberg.org/ebooks/16713
  # Image https://www.gutenberg.org/files/16713/16713-h/images/q243.png
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32239

  require Graph;
  my $graph = Graph->new(undirected => 1);
  $graph->add_edge('01',12); $graph->add_edge('01','09');
  $graph->add_edge('02',13); $graph->add_edge('02',10);
  $graph->add_edge('03','07');  $graph->add_edge('03',12);
  $graph->add_edge('03',14); $graph->add_edge('03',11);
  $graph->add_edge('04','08');  $graph->add_edge('04',13); $graph->add_edge('04',15);
  $graph->add_edge('05','09');  $graph->add_edge('05',14);
  $graph->add_edge('06',10); $graph->add_edge('06',15);

  $graph->add_edge('07',13);
  $graph->add_edge('08',14);
  $graph->add_edge('09',15); $graph->add_edge('09',16);
  $graph->add_edge(10,12);
  $graph->add_edge(11,13); $graph->add_edge(11,16);
  $graph->add_edge(12,16);
  $graph->vertices == 16 or die;

  foreach my $i (1..6) {
    $graph->set_vertex_attribute ("0$i", 'xy', "$i,2");
  }
  foreach my $i (7..9) {
    $graph->set_vertex_attribute ("0$i", 'xy', ($i-6).",1");
  }
  foreach my $i (10..11) {
    $graph->set_vertex_attribute ($i, 'xy', ($i-6).",1");
  }
  foreach my $i (12..15) {
    $graph->set_vertex_attribute ($i, 'xy', ($i-10).",0");
  }
  $graph->set_vertex_attribute (16, 'xy', "4,-1");

  {
    my @degrees = map {$graph->degree($_)} sort $graph->vertices;
    join(',',@degrees) eq '2,2,4,3,2,2,2,2,4,3,3,4,4,3,3,3' or die;
  }
  foreach my $i (1..6) {
    $graph->set_vertex_attribute ("0$i", 'xy', "$i,2");
  }

  # MyGraphs::Graph_view($graph);
  # foreach my $v ($graph->vertices) {
  #   $graph->delete_vertex_attribute($v,'xy');
  # }
  # MyGraphs::Graph_view($graph);

  MyGraphs::Graph_print_dreadnaut($graph);
  MyGraphs::hog_searches_html($graph);
  # MyGraphs::Graph_print_tikz($graph);

  require IPC::Run;
  my $g6str = MyGraphs::Graph_to_graph6_str($graph);
  IPC::Run::run (['nauty-hamheuristic', '-v'],
                 '<', \$g6str);

  MyGraphs::Graph_is_Hamiltonian($graph, type=>'cycle', start => '01',
                                 verbose=>1, all=>1);
  exit 0;
}
{
  # Henry Ernest Dudeney, "Amusements in Mathematics", 1917, puzzle 248 "The
  # Cyclists' Tour", page 71.
  # http://www.gutenberg.org/ebooks/16713
  # Image https://www.gutenberg.org/files/16713/16713-h/images/q248.png
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32237

  require Graph;
  my $graph = Graph->new(undirected => 1);
  $graph->add_path('O','N'); $graph->add_path('O','W');
  $graph->add_path('N','A'); $graph->add_path('N','star');
  $graph->add_path('star','Y');
  $graph->add_edge('Y','I'); $graph->add_edge('Y','A');
  $graph->add_edge('M','I'); $graph->add_edge('M','S');
  $graph->add_edge('M','R'); $graph->add_edge('M','A');
  $graph->add_edge('S','U');
  $graph->add_edge('I','E');
  $graph->add_edge('A','W');
  $graph->add_path('E','R');
  $graph->add_path('R','U');

  my @Hamiltonian = ('N','O', 'W','A','Y', 'I','M', 'S','U','R','E');
  foreach my $i (0 .. $#Hamiltonian-1) {
    $graph->has_edge($Hamiltonian[$i], $Hamiltonian[$i+1])
      or die "Not $Hamiltonian[$i], $Hamiltonian[$i-1]";;
  }

  # MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  # MyGraphs::Graph_print_tikz($graph);

  {
    my $grid = Graph->new(undirected => 1);
    $grid->add_path('star','Y','I','E', 'R','M','A','N', 'star');
    $grid->add_path('N','O','W','A','Y','I','M','S','U','R','E');
    MyGraphs::Graph_is_isomorphic($graph,$grid) or die;
  }

  require IPC::Run;
  my $g6str = MyGraphs::Graph_to_graph6_str($graph);
  IPC::Run::run (['nauty-hamheuristic', '-v'],
                 '<', \$g6str);

  print "Hamiltonian cycle:\n";
  MyGraphs::Graph_is_Hamiltonian($graph, type=>'cycle', start => 'star',
                                 verbose=>1, all=>1);
  exit 0;
}
