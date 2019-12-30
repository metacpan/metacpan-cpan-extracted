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
use FindBin;
use File::Slurp;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Maker::RookGrid;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs ();

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 3;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','RookGrid.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    while ($content =~ /^ +(?<id>\d+) +(?<dims>[0-9,]+)/mg) {
      $count++;
      my $id   = $+{'id'};
      my $dims = $+{'dims'};
      $shown{"$dims"} = $+{'id'};
    }
    ok ($count, 20, 'HOG ID number lines');
  }
  ok (scalar(keys %shown), 20);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my $try = sub {
    my ($dims) = @_;
    my $graph = Graph::Maker->new('rook_grid', undirected => 1,
                                  dims => $dims);
    return if MyGraphs::Graph_loopcount($graph);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    my $key = join(',', @$dims);
    if (my $id = $shown{$key}) {
      ### compare: $key
      MyGraphs::hog_compare($id, $g6_str);
      $compared++;
    } else {
      $others++;
      if (MyGraphs::hog_grep($g6_str)) {
        my $name = $graph->get_graph_attribute('name');
        MyTestHelpers::diag ("HOG key=\"$key\" not shown in POD");
        MyTestHelpers::diag ($name);
        MyTestHelpers::diag ($g6_str);
        # MyGraphs::Graph_view($graph);
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
}

#------------------------------------------------------------------------------
exit 0;
