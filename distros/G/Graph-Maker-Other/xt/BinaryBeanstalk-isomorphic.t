#!/usr/bin/perl -w

# Copyright 2017, 2018 Kevin Ryde
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

use Graph::Maker::BinaryBeanstalk;

use lib 'devel/lib';
use MyGraphs;

plan tests => 4;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown_height = (1 => 1,
                      2 => 2,
                      4 => 3,
                      6 => 4,
                      8 => 5);

  my %shown = (1  => 1310,   # N=1 single vertex
               2  => 19655,  # N=2 path-2
               3  => 32234,  # N=3 path-3

               4  => 500,    # height=3
               5  => 30,
               6  => 334,    # height=4
               7  => 714,
               8  => 502,    # height=5
               13 => 60,
              );
  my $extras = 0;
  my %seen;
  foreach my $N (3 .. 64) {
    my $graph = Graph::Maker->new('binary_beanstalk', undirected => 1,
                                  N => $N);
    if (defined (my $height = $shown_height{$N})) {
      my $gh = Graph::Maker->new('binary_beanstalk', undirected => 1,
                                 height => $height);
      ok ("$gh", "$graph", "N=$N height=$height");
    }

    my $key = "$N";
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    if (my $id = $shown{$key}) {
      MyGraphs::hog_compare($id, $g6_str);
    } else {
      if (MyGraphs::hog_grep($g6_str)) {
        MyTestHelpers::diag ("HOG got $key, not shown in POD");
        MyTestHelpers::diag ($g6_str);
        MyGraphs::Graph_view($graph);
        $extras++
      }
    }
  }
  ok ($extras, 0);
}

#------------------------------------------------------------------------------
exit 0;
