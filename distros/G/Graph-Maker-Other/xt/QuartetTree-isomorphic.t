#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019 Kevin Ryde
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
use File::Slurp;
use FindBin;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Maker::QuartetTree;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs ();

plan tests => 3;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','QuartetTree.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    while ($content =~ /^ +(?<id>\d+) +level=(?<level>\d+)/mg) {
      $count++;
      my $id    = $+{'id'};
      my $level = $+{'level'};
      $shown{"level=$level"} = $+{'id'};
    }
    ok ($count, 4, 'HOG ID number lines');
  }
  ok (scalar(keys %shown), 4);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my $try = sub {
    my @params = @_;
    my $graph = Graph::Maker->new('quartet_tree', undirected => 1, @params);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    my $key = join('=',@params);
    if (my $id = $shown{$key}) {
      MyGraphs::hog_compare($id, $g6_str);
      $compared++;
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
  # 5^4 == 625 about HOG 255 limit
  foreach my $level (0 .. 4) {
    $try->(level => $level);
  }
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
  ok ($extras, 0);
}

#------------------------------------------------------------------------------
exit 0;
