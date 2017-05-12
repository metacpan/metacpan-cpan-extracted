# Copyright 2015, 2016, 2017 Kevin Ryde
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


package Graph::Maker::DragonByPath;
use 5.004;
use strict;
use Graph::Maker;
use Math::PlanePath::DragonCurve 117; # v.117 for level_to_n_range()

use vars '$VERSION','@ISA';
$VERSION = 6;
@ISA = ('Graph::Maker');

sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

my @_BlobN = (3, 6, 12, 9);
sub _BlobN {
  my ($k) = @_;
  return (2**($k+1) + $_BlobN[$k%4])/5;
}

sub init {
  my ($self, %params) = @_;

  my $level = delete($params{'level'}) || 0;
  my $arms = delete($params{'arms'}) || 1;
  my $part = delete($params{'part'}) || 'dragon';
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);
  my $path = Math::PlanePath::DragonCurve->new (arms => $arms);

  my ($n_lo, $n_hi);
  if ($part eq 'blob') {
    if ($level < 4) {
      # an empty graph
      return $graph;
    }
    $n_lo = _BlobN($level);
    $n_hi = _BlobN($level+1)-3;
  } else {
    ($n_lo, $n_hi) = $path->level_to_n_range($level);
  }

  foreach my $n ($n_lo .. $n_hi - $arms) {
    my ($fx,$fy) = $path->n_to_xy($n);
    my ($tx,$ty) = $path->n_to_xy($n + $arms);
    $graph->add_edge("$fx,$fy", "$tx,$ty");
  }
  return $graph;
}

Graph::Maker->add_factory_type('dragon_by_planepath' => __PACKAGE__);
1;
