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

use Graph::Maker::RookGrid;

use lib 'devel/lib';
use MyGraphs ();

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 2;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown = ('1,1' => 1310,
               '1,2' => 19655,
               '1,3' => 1374,
               '1,4' => 74,
               '1,5' => 462,
               '1,6' => 232,
               '1,7' => 58,
               '1,8' => 180,
               '2,2' => 674,
               '2,3' => 746,
               '3,3' => 6607,
               '4,4' => 30317,
               '2,2,2' => 1022,
               '2,2,2,2' => 1340,
               '2,2,2,2,2' => 28533,
              );
  my %unseen = %shown;
  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my $try = sub {
    my ($dims, $cyclic) = @_;
    my $graph = Graph::Maker->new('rook_grid', undirected => 1,
                                  dims => $dims,
                                  cyclic => $cyclic);
    return if MyGraphs::Graph_loopcount($graph);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    my $key = join(',', @$dims, ($cyclic?'cyclic':()));
    if (my $id = $shown{$key}) {
      ### compare: $key
      MyGraphs::hog_compare($id, $g6_str);
      $compared++;
      delete $unseen{$key};
    } else {
      $others++;
      if (MyGraphs::hog_grep($g6_str)) {
        my $name = $graph->get_graph_attribute('name');
        MyTestHelpers::diag ("HOG $key not shown in POD");
        MyTestHelpers::diag ($name);
        MyTestHelpers::diag ($g6_str);
        MyGraphs::Graph_view($graph);
        $extras++;
      }
    }
  };
  $try->([8,8]);
  foreach my $X (1 .. 8) {
    foreach my $Y ($X .. 8) {
      $try->([$X,$Y]);
    }
  }
  foreach my $X (2 .. 6) {
    foreach my $Y ($X .. 6) {
      foreach my $Z ($Y .. 6) {
        $try->([$X,$Y,$Z]);
      }
    }
  }
  foreach my $X (2 .. 4) {
    foreach my $Y ($X .. 4) {
      foreach my $Z ($Y .. 4) {
        foreach my $W ($Z .. 4) {
          $try->([$X,$Y,$Z,$W]);
        }
      }
    }
  }
  foreach my $X (2 .. 3) {
    foreach my $Y ($X .. 3) {
      foreach my $Z ($Y .. 3) {
        foreach my $W ($Z .. 3) {
          foreach my $U ($W .. 3) {
            $try->([$X,$Y,$Z,$W,$U]);
          }
        }
      }
    }
  }
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
  ok ($extras, 0);
  ok (scalar(keys %unseen), 0);
  if (%unseen) {
    MyTestHelpers::diag ("unseen: ",join(' ',keys %unseen));
  }
}

#------------------------------------------------------------------------------
exit 0;
