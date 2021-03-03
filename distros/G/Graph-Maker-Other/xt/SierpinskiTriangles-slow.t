#!/usr/bin/perl -w

# Copyright 2020, 2021 Kevin Ryde
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
use FindBin;
use File::Spec;
use File::Slurp;

# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

require Graph::Maker::SierpinskiTriangles;

plan tests => 3;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'devel',
                           'lib','Graph','Maker','SierpinskiTriangles.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?(?==head1)/s or die;
    $content = $&;
    $content =~ s/.*?=back//s;
    ### $content
    my $count = 0;
    while ($content =~ /^ +(?<id>\d+) +N=(?<N>\d+)/mg) {
      $count++;
      my $N  = $+{'N'};
      my $key = "N=$N";
      $shown{$key} = $+{'id'};
      ### $key
      ### id: $+{'id'}
    }
    ok ($count, 2, 'HOG ID number lines');
  }
  ok (scalar(keys %shown), 2);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my %seen;
  foreach my $N (0 .. 5) {
    my $graph = Graph::Maker->new('Sierpinski_triangles', undirected => 1,
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
        MyGraphs::Graph_view($graph);
        $extras++;
      }
    }
    # last if $graph->vertices > 255;
  }
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
  ok ($extras, 0);
}


#------------------------------------------------------------------------------
exit 0;
