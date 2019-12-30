#!/usr/bin/perl -w

# Copyright 2019 Kevin Ryde
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

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # Martin Gardner, "Mathematical Games", Scientific American, volume 206,
  # number 2, February 1962, and number 3, March 1962.  Reprinted in Martin
  # Gardner, "The Colossal Book of Short Puzzles and Problems", W.W. Norton
  # and Company, 2006, ISBN 0-393-06114-0 (hardback), problem 1.8, pages
  # 6-7, 20-22.
  #
  # D. K. Cahoon, "The No-Touch Puzzle and Some Generalizations", Mathematics
  # Magazine, volume 45, November 1972, pages 261-265.

  # Assign labels 1 to 8 so no edge between consecutive numbers.
  # Per both O'Beirne and Koplowitz, go to the graph complement where
  # consecutive numbers must have an edge between, so a Hamiltonian path.

  # graph
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=33772
  # complement
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=33774

  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle(2,5,3,7,4,6);
  $graph->add_cycle(3,1,4,8);
  $graph->add_cycle(5,1,6,8);
  $graph->add_path(7,1,8,2);
  MyGraphs::Graph_set_xy_points($graph,
                                1 => [0,2],
                                2 => [0,0],
                                3 => [-1,2],
                                4 => [1,2],
                                5 => [-1,1],
                                6 => [1,1],
                                7 => [0,3],
                                8 => [0,1]);

  MyGraphs::Graph_run_dreadnaut($graph, verbose=>1);

  my $complement = $graph->complement;
  MyGraphs::Graph_set_xy_points($complement,
                                1 => [0,0],
                                2 => [1,0],
                                3 => [2,-1],
                                4 => [2,1],
                                5 => [3,1],
                                6 => [3,-1],
                                7 => [4,0],
                                8 => [5,0]);
  MyGraphs::Graph_run_dreadnaut($complement, verbose=>1);
  MyGraphs::hog_upload_html($complement);
  MyGraphs::hog_searches_html($graph, $complement);
  MyGraphs::Graph_view($complement);
  exit 0;
}
