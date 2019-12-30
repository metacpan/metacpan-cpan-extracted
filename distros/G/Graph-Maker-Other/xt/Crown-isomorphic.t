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

use Graph::Maker::Crown;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 13;


#------------------------------------------------------------------------------

{
  # Crown 4 = Cube (Hypercube 3)

  require Graph::Maker::Hypercube;
  my $crown = Graph::Maker->new('crown', N=>4, undirected=>1);
  my $cube  = Graph::Maker->new('hypercube', N=>3, undirected=>1);
  ok (!! MyGraphs::Graph_is_isomorphic($crown, $cube),
      1,
      "Crown 4 = Cube");
}
{
  # Crown = complement of RookGrid Nx2

  require Graph::Maker::RookGrid;
  foreach my $N (2 .. 10) {
    my $crown = Graph::Maker->new('crown', N=>$N, undirected=>1);
    my $rook = Graph::Maker->new('rook_grid', dims=>[$N,2], undirected=>1);
    my $rook_complement = $rook->complement;
    ok (!! MyGraphs::Graph_is_isomorphic($crown, $rook_complement),
        1,
        "Crown $N = Rook $N,2 complement");
  }
}

#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','Crown.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    while ($content =~ /^ +(?<id>\d+) +N=(?<N>\d+)/mg) {
      $count++;
      my $id = $+{'id'};
      my $N  = $+{'N'};
      $shown{"N=$N"} = $+{'id'};
    }
    ok ($count, 7, 'HOG ID number of lines');
  }
  ok (scalar(keys %shown), 7);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my %seen;
  foreach my $N (0 .. 10) {
    my $graph = Graph::Maker->new('crown', undirected => 1,
                                  N => $N);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    next if $seen{$g6_str}++;
    my $key = "N=$N";
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
        # MyGraphs::Graph_view($graph);
        $extras++;
      }
    }
  }
  ok ($extras, 0);
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
}

#------------------------------------------------------------------------------
exit 0;
