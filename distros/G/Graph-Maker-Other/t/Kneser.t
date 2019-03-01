#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019 Kevin Ryde
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
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 50;

require Graph::Maker::Kneser;

sub binomial {
  my ($n, $m) = @_;
  my $ret = 1;
  foreach my $i ($n-$m+1 .. $n) {
    $ret *= $i;
  }
  foreach my $i (1 .. $m) {
    $ret /= $i;
  }
  return $ret;
}
ok (binomial(3,0), 1);
ok (binomial(3,1), 3);
ok (binomial(3,2), 3);
ok (binomial(3,3), 1);

ok (binomial(4,0), 1);
ok (binomial(4,1), 4);
ok (binomial(4,2), 6);
ok (binomial(4,3), 4);
ok (binomial(4,4), 1);


#------------------------------------------------------------------------------
{
  my $want_version = 13;
  ok ($Graph::Maker::Kneser::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Kneser->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Kneser->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Kneser->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# Kneser N,K no edges when K > N/2

require Graph::Maker::Complete;
foreach my $N (1 .. 7) {
  foreach my $K (int($N/2)+1 .. $N) {
    my $graph  = Graph::Maker->new('Kneser', N=>$N, K=>$K);
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    ok ($num_vertices, binomial($N,$K));
    ok ($num_edges, 0);
  }
}


#------------------------------------------------------------------------------
# Kneser N,1 is complete-N, same vertex numbers too

require Graph::Maker::Complete;
foreach my $N (2 .. 6) {
  my $Kneser  = Graph::Maker->new('Kneser', N=>$N, K=>1);
  my $complete = Graph::Maker->new('complete', N=>$N);
  ok ($Kneser eq $complete, 1);
}


#------------------------------------------------------------------------------
exit 0;
