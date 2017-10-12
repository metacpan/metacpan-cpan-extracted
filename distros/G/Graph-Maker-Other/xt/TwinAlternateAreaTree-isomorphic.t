#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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

use Graph::Maker::TwinAlternateAreaTree;

use lib 'devel/lib';
use MyGraphs;

plan tests => 1;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown = ('0' => 1310,
               '1' => 19655,
               '2' => 594,
               '3' => 260,
               '4' => 27042,
               '5' => 27044,
               '6' => 27046,
              );
  my $extras = 0;
  my %seen;
  foreach my $level (0 .. 8) {
    my $graph = Graph::Maker->new('twin_alternate_area_tree', undirected => 1,
                                  level => $level);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    next if $seen{$g6_str}++;
    if (my $id = $shown{$level}) {
      MyGraphs::hog_compare($id, $g6_str);
    } else {
      if (MyGraphs::hog_grep($g6_str)) {
        MyTestHelpers::diag ("HOG $level not shown in POD");
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
