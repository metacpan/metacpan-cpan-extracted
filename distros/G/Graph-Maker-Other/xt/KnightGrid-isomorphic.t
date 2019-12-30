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
use File::Spec;
use File::Slurp;
use FindBin;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Maker::KnightGrid;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 6;


#------------------------------------------------------------------------------

{
  # KnightGrid 4,3 cyclic = Circulant N=12 2,5
  my $knight = Graph::Maker->new('knight_grid', undirected => 1,
                                 dims => [4,3], cyclic=>1);
  require Graph::Maker::Circulant;
  my $circulant = Graph::Maker->new('circulant', undirected => 1,
                                    N => 12, offset_list => [1,2,5]);
  ok (MyGraphs::Graph_is_isomorphic($knight, $circulant));
}
{
  # KnightGrid 6,2 cyclic = Circulant N=12 1,5
  my $knight = Graph::Maker->new('knight_grid', undirected => 1,
                                 dims => [6,2], cyclic=>1);
  require Graph::Maker::Circulant;
  my $circulant = Graph::Maker->new('circulant', undirected => 1,
                                    N => 12, offset_list => [1,5]);
  ok (MyGraphs::Graph_is_isomorphic($knight, $circulant));
}


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','KnightGrid.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $rel_type;
    my $count = 0;
    while ($content =~ /^ +(?<id>\d+) +(?<spec>([0-9x]| cyclic| or )+)/mg) {
      $count++;
      my $id = $+{'id'};
      foreach my $params (split / or /, $+{'spec'}) {
        $params =~ /([0-9x]+)( cyclic)?/ or die;
        my $dims = $1;
        my $cyclic = $2 ? 1 : 0;
        $shown{"dims=$dims,cyclic=$cyclic"} = $id;
      }
    }
    ok ($count, 17, 'HOG ID number lines');
  }
  ok (scalar(keys %shown), 18);
  ### %shown

  my %seen;
  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my $try = sub {
    my ($dims, $cyclic) = @_;
    join(',',sort {$b<=>$a} @$dims) eq join(',',@$dims)
      or die "dims should be descending order, got: ",join(',',@$dims);
    $cyclic //= 0;
    my $graph = Graph::Maker->new('knight_grid', undirected => 1,
                                  dims => $dims,
                                  cyclic => $cyclic);
    return if MyGraphs::Graph_loopcount($graph);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    my $key = "dims=".join('x', @$dims) . ",cyclic=$cyclic";
    if (my $id = $shown{$key}) {
      ### compare: $key
      MyGraphs::hog_compare($id, $g6_str);
      $compared++;
    } else {
      $others++;
      if (MyGraphs::hog_grep($g6_str)) {
        my $name = $graph->get_graph_attribute('name');
        MyTestHelpers::diag ("HOG $key not shown in POD");
        MyTestHelpers::diag ($name);
        MyTestHelpers::diag ($g6_str);
        # MyGraphs::Graph_view($graph);
        $extras++;
        exit 1;
      }
    }
  };
  $try->([8,8]);
  foreach my $cyclic (0, 1) {
    foreach my $X (2 .. 6) {
      foreach my $Y (2 .. $X) {
        $try->([$X,$Y],$cyclic);
      }
    }
  }
  foreach my $cyclic (0, 1) {
    foreach my $X (2 .. 6) {
      foreach my $Y (2 .. $X) {
        foreach my $Z (2 .. $Y) {
          $try->([$X,$Y,$Z],$cyclic);
        }
      }
    }
  }
  foreach my $cyclic (0, 1) {
    foreach my $X (2 .. 4) {
      foreach my $Y (2 .. $X) {
        foreach my $Z (2 .. $Y) {
          foreach my $W (2 .. $Z) {
            $try->([$X,$Y,$Z,$W],$cyclic);
          }
        }
      }
    }
  }
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
  ok ($extras, 0);
  ok ($compared, scalar(keys %shown));
}

#------------------------------------------------------------------------------
exit 0;
