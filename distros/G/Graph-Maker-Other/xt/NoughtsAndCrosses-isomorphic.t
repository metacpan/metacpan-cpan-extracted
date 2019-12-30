#!/usr/bin/perl -w

# Copyright 2017, 2019 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Maker::NoughtsAndCrosses;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

plan tests => 8;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown = ("2" => 27017,
               "2,rotate=1" => 27020,
               "2,rotate=1,reflect=1" => 945,

               "2,players=1" => 27032,
               "2,players=1,reflect=1" => 856,
               "2,players=1,rotate=1" => 500, # claw

               "2,players=3,rotate=1" => 27025,
               "2,players=3,rotate=1,reflect=1" => 27048,

               "2,players=4,rotate=1" => 27034,
               "2,players=4,rotate=1,reflect=1" => 27050,

               "3,players=1,rotate=1,reflect=1" => 27015,
              );
  my $extras = 0;
  my %seen;
  foreach my $N (2 .. 2) {
    foreach my $players (1 .. $N*$N) {
      foreach my $rotate (0, 1) {
        foreach my $reflect (0, 1) {
          my $graph = Graph::Maker->new('noughts_and_crosses', undirected => 1,
                                        N => $N, players => $players,
                                        rotate => $rotate, reflect => $reflect,
                                       );
          next if $graph->vertices > 64;
          my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
          $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
          next if $seen{$g6_str}++;
          my $key = "$N";
          if ($players != 2) { $key .= ",players=$players"; }
          if ($rotate) { $key .= ",rotate=$rotate"; }
          if ($reflect) { $key .= ",reflect=$reflect"; }
          if (my $id = $shown{$key}) {
            MyGraphs::hog_compare($id, $g6_str);
          } else {
            if (MyGraphs::hog_grep($g6_str)) {
              my $name = $graph->get_graph_attribute('name');
              MyTestHelpers::diag ("HOG $key not shown in POD");
              MyTestHelpers::diag ($name);
              MyTestHelpers::diag ($g6_str);
              MyGraphs::Graph_view($graph);
              $extras++
            }
          }
        }
      }
    }
  }
  ok ($extras, 0);
}

#------------------------------------------------------------------------------
# 2x2

{
  #  2x2 1-player equivalent to half a tesseract
  #
  my $noughts = Graph::Maker->new('noughts_and_crosses',
                                  N => 2,
                                  players => 1,
                                  undirected => 1);
  ok (scalar($noughts->vertices), 11);
  ok (scalar($noughts->edges), 16);

  my @centres = $noughts->centre_vertices;
  ok (scalar(@centres), 1);
  ok (join(',',sort @centres), '0000');

  require Graph::Maker::Hypercube;
  my $tesseract = Graph::Maker->new('hypercube',
                                    N => 4,
                                    undirected => 1);
  ok (scalar($tesseract->edges), 2*16);

  ok (!! MyGraphs::Graph_is_induced_subgraph($tesseract,$noughts), 1);


  # half by deleting one vertex and its neighbours
  my @vertices = $tesseract->vertices;
  my $v = $vertices[0];
  my @delete = ($vertices[0]);
  $tesseract->delete_vertices($v, $tesseract->neighbours($v));

  ok (!! MyGraphs::Graph_is_isomorphic($tesseract,$noughts), 1);

  # MyGraphs::Graph_view($tesseract);
  # MyGraphs::Graph_view($noughts);
}

#------------------------------------------------------------------------------
exit 0;
