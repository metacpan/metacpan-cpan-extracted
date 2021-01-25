#!/usr/bin/perl -w

# Copyright 2019, 2021 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use File::Slurp;
use FindBin;
use Graph;
use List::Util 'min', 'max';

use Test;
plan tests => 5;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::AlternatePaper;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;


#------------------------------------------------------------------------------

sub make_graph {
  my ($level) = @_;
  my $path = Math::PlanePath::AlternatePaper->new;
  my $graph = Graph->new (undirected => 1);
  my ($n_lo, $n_hi) = $path->level_to_n_range($level);
  foreach my $n ($n_lo .. $n_hi) {
    my ($x,$y) = $path->n_to_xy($n);
    $graph->add_vertex("$x,$y");
  }
  foreach my $n ($n_lo .. $n_hi-1) {
    my ($x,$y) = $path->n_to_xy($n);
    my ($x2,$y2) = $path->n_to_xy($n+1);
    $graph->add_edge("$x,$y", "$x2,$y2");
  }
  return $graph;
}

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Math','PlanePath','AlternatePaper.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    while ($content =~ /^ +(?<id>\d+) +level=(?<level>\d+)/mg) {
      $count++;
      my $id    = $+{'id'};
      my $level = $+{'level'};
      $shown{"level=$level"} = $+{'id'};
    }
    ok ($count, 9, 'HOG ID number of lines');
  }
  ok (scalar(keys %shown), 9);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my %seen;
  foreach my $level (0 .. 9) {
    my $graph = make_graph($level);
    last if $graph->vertices >= 256;
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    next if $seen{$g6_str}++;
    my $key = "level=$level";
    if (my $id = $shown{$key}) {
      MyGraphs::hog_compare($id, $g6_str);
      $compared++;
    } else {
      $others++;
      if (MyGraphs::hog_grep($g6_str)) {
        MyTestHelpers::diag ("HOG $key in HOG, not shown in POD");
        my $name = $graph->get_graph_attribute('name');
        MyTestHelpers::diag ($name);
        MyTestHelpers::diag ($g6_str);
        # MyGraphs::Graph_view($graph);
        $extras++;
      }
    }
  }
  ok ($extras, 0);
  ok ($others, 0);
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
}

#------------------------------------------------------------------------------
# A086341 - Graph Diameter, k>=3

MyOEIS::compare_values
  (anum => 'A086341',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my $graph = make_graph($k);
       my $got= $graph->diameter;
       if ($k==1) { $got == 2 or die; $got = 3; }  # exceptions
       if ($k==2) { $got == 4 or die; $got = 3; }
       push @got, $got;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
