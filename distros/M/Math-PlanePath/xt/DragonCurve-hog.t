#!/usr/bin/perl -w

# Copyright 2019 Kevin Ryde

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
use Carp 'croak';
use File::Slurp;
use FindBin;
use Graph;
use List::Util 'min', 'max';
$|=1;

use Test;
plan tests => 4;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::DragonCurve;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;


#------------------------------------------------------------------------------

sub BlobN {
  my ($k) = @_;
  if ($k < 4) { croak "No blob k=$k"; }
  my $ret = 7;
  foreach my $i (5 .. $k) {
    $ret = 2*$ret - (($i-1) % 4 < 2 ? 0 : 3);
  }
  return $ret;
}

sub make_graph {
  my ($level, $blob) = @_;
  my $path = Math::PlanePath::DragonCurve->new;
  my $graph = Graph->new (undirected => 1);
  my ($n_lo, $n_hi);
  if ($blob) {
    $n_lo = BlobN($level);
    $n_hi = BlobN($level+1) - 3;
  } else {
    ($n_lo, $n_hi) = $path->level_to_n_range($level);
  }
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
                           'lib','Math','PlanePath','DragonCurve.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    my $type = '';
    while ($content =~ /^( +(?<id>\d+) +level=(?<level>\d+)|And for just a (?<blob>blob))/mg) {
      if ($+{'blob'}) {
        $type = 'blob,';
      } else {
        $count++;
        my $id    = $+{'id'};
        my $level = $+{'level'};
        $shown{"${type}level=$level"} = $+{'id'};
      }
    }
    ok ($type, 'blob,');
    ok ($count, 15, 'HOG ID number of lines');
  }
  ok (scalar(keys %shown), 15);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my %seen;
  foreach my $blob (0, 1) {
    my $type = ($blob ? 'blob,' : '');
    foreach my $level (($blob ? 4 : 0) .. 10) {
      my $graph = make_graph($level, $blob);
      last if $graph->vertices >= 256;
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      next if $seen{$g6_str}++;
      my $key = "${type}level=$level";
      if (my $id = $shown{$key}) {
        MyGraphs::hog_compare($id, $g6_str);
        $compared++;
      } else {
        $others++;
        if (MyGraphs::hog_grep($g6_str)) {
          my $name = $graph->get_graph_attribute('name');
          MyTestHelpers::diag ("HOG $key in HOG, not shown in POD");
          MyTestHelpers::diag ($name);
          MyTestHelpers::diag ($g6_str);
          # MyGraphs::Graph_view($graph);
          $extras++;
        }
      }
    }
  }
  ok ($extras, 0);
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
}

#------------------------------------------------------------------------------
exit 0;
