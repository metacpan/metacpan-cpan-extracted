#!/usr/bin/perl -w

# Copyright 2019, 2021 Kevin Ryde
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
use File::Spec;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

use Graph::Maker::FibonacciTree;

plan tests => 3;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my @option = ('series_reduced', 'leaf_reduced');

  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','FibonacciTree.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my @type_list;
    my $count = 0;
    while ($content =~ /^    (?<type>[^ ].+)|^      (?<id>\d+) +height=(?<height>\d+)/mg) {
      if (defined $+{'type'}) {
        my $type = $+{'type'};
        if ($type eq 'default') {
          @type_list = ("series_reduced=0,leaf_reduced=0");
        } elsif ($type eq 'all') {
          @type_list = ();
          foreach my $series_reduced (0,1) {
            foreach my $leaf_reduced (0,1) {
              push @type_list, "series_reduced=$series_reduced,leaf_reduced=$leaf_reduced";
            }
          }
        } elsif ($type eq 'series_reduced=1') {
          @type_list = ("series_reduced=1,leaf_reduced=0");
        } elsif ($type eq 'leaf_reduced=1') {
          @type_list = ("series_reduced=0,leaf_reduced=1");
        } elsif ($type eq 'series_reduced=1, leaf_reduced=1') {
          @type_list = ("series_reduced=1,leaf_reduced=1");
        } else {
          die "unrecognised type: $type";
        }
      } else {
        $count++;
        my $height = $+{'height'};
        foreach my $type (@type_list) {
          $shown{"height=$height,$type"} = $+{'id'};
        }
      }
    }
    ok ($count, 13, 'HOG ID number lines');
  }
  ok (scalar(keys %shown), 16);
  ### %shown

  my $extras = 0;
  my %seen;
  foreach my $height (1 .. 6) {
    foreach my $series_reduced (0,1) {
      foreach my $leaf_reduced (0,1) {
        my $graph = Graph::Maker->new('fibonacci_tree', height => $height,
                                      series_reduced => $series_reduced,
                                      leaf_reduced => $leaf_reduced,
                                      undirected => 1);
        my $key = "height=$height,series_reduced=$series_reduced,leaf_reduced=$leaf_reduced";
        ### $key
        my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
        $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
        if (my $id = $shown{$key}) {
          MyGraphs::hog_compare($id, $g6_str);
        } else {
          if (my $id = MyGraphs::hog_grep($g6_str)) {
            MyTestHelpers::diag ("HOG got $key, not shown in POD, id=$id");
            MyTestHelpers::diag ($g6_str);
            MyGraphs::Graph_view($graph);
            $extras++
          }
        }
      }
    }
  }
  ok ($extras, 0);
}


#------------------------------------------------------------------------------
exit 0;
