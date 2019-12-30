#!/usr/bin/perl -w

# Copyright 2019 Kevin Ryde
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
use List::Util 'sum';
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 2174;

use FindBin;
use lib "$FindBin::Bin/../..";

require Graph::Maker::BinomialBoth;


#------------------------------------------------------------------------------
{
  my $want_version = 14;
  ok ($Graph::Maker::BinomialBoth::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::BinomialBoth->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::BinomialBoth->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::BinomialBoth->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# Descendants

# Bit mask of 1s for all the low 0s.
sub mask_low_0s {
  my ($n) = @_;
  return ($n ? ($n ^ ($n-1)) >> 1 : 0);
}
ok(mask_low_0s(0), 0);
ok(mask_low_0s(1), 0);
ok(mask_low_0s(2), 1);
ok(mask_low_0s(12), 3);
foreach my $n (1 .. 64) {
  my $m = mask_low_0s($n);
  ok ($n & $m, 0);
  ok (($n & ($m+1)) != 0, 1,
      "n=$n m=$m");
}

# Bit mask of 1s for all the low 1s.
sub mask_low_1s {
  my ($n) = @_;
  return mask_low_0s($n+1);
}
foreach my $n (0 .. 64) {
  my $m = mask_low_1s($n);
  ok ($n & $m,  $m);
  ok (($n & ($m+1)) == 0, 1,
      "n=$n m=$m");
}

# Bit mask of a single 1 where the lowest 0 in $n.
sub mask_lowest_0 {
  my ($n) = @_;
  return mask_low_1s($n) + 1;
}
ok(mask_lowest_0(0), 1);
ok(mask_lowest_0(1), 2);
ok(mask_lowest_0(2), 1);
ok(mask_lowest_0(3), 4);
ok(mask_lowest_0(5), 2);
ok(mask_lowest_0(13), 2);
foreach my $n (0 .. 64) {
  my $m = mask_lowest_0($n);
  while ($m >>= 1) {
    ok (($n & $m) != 0, 1);
  }
}

# As described in the POD.
sub want_descendants {
  my ($v, $order) = @_;
  my $limit = (1<<$order) - 1;
  my $low = ($v == 0 ? $limit : mask_low_0s($v));
  my @ret = ($v .. $v + $low);
  $v += $low;
  for (;;) {
    $low = mask_lowest_0($v);
    last if $low > $limit;
    $v += $low;
    push @ret, $v;
  }
  return @ret;
}

{
  # directed
  foreach my $order (0 .. 8) {
    my $graph = Graph::Maker->new('binomial_both', order => $order,
                                 direction_type => 'bigger');

    foreach my $v ($graph->vertices) {
      my @descendants = sort {$a<=>$b} $v, $graph->all_successors($v);
      ok (join(',',@descendants),
          join(',',want_descendants($v,$order)),
          "descendants v=$v");
    }
  }
}

#------------------------------------------------------------------------------
# Sub-Graph of BinomialTree

{
  # directed
  foreach my $order (0 .. 8) {
    my $lattice = Graph::Maker->new('binomial_both', order => $order,
                                 direction_type => 'both');
    require Graph::Maker::BinomialTree;
    my $tree = Graph::Maker->new('binomial_tree', order => $order);
    # require MyGraphs;
    # MyGraphs::Graph_view($tree);
    # MyGraphs::Graph_view($lattice);

    foreach my $edge ($tree->edges) {
      my ($from,$to) = @$edge;
      ok ($lattice->has_edge($from,$to) ? 1 : 0,  1,
          "order=$order lattice has tree edge $from to $to");
    }
  }
}

#------------------------------------------------------------------------------
# No Duplicate Edges

# As shown in the POD.
sub want_num_edges {
  my ($k) = @_;
  return ($k == 0 ? 0 : 3*2**($k-1) - 2);
}

foreach my $multiedged (0, 1) {
  foreach my $undirected (0, 1) {
    foreach my $direction_type ('bigger','smaller','both') {
      foreach my $order (0 .. 8) {
        my $graph = Graph::Maker->new('binomial_both',
                                      undirected => $undirected,
                                      multiedged => $multiedged,
                                      order => $order,
                                      direction_type => $direction_type);
        ok ($graph->is_multiedged ? 1 : 0, $multiedged);

        my $num_vertices = $graph->vertices;
        my $num_edges = $graph->edges;
        ok ($num_vertices, 2**$order);
        ok ($num_edges,
            want_num_edges($order)
            * (!$undirected && $direction_type eq 'both' ? 2 : 1),
            "num edges multiedged=$multiedged");
      }
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
