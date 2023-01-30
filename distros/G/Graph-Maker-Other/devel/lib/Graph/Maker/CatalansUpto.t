#!/usr/bin/perl -w

# Copyright 2019, 2020, 2021 Kevin Ryde
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

plan tests => 969;

use FindBin;
use lib "$FindBin::Bin/../..";

# uncomment this to run the ### lines
# use Smart::Comments;

require Graph::Maker::CatalansUpto;


#------------------------------------------------------------------------------
{
  my $want_version = 19;
  ok ($Graph::Maker::CatalansUpto::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::CatalansUpto->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::CatalansUpto->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::CatalansUpto->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# Helpers

# A000108            n =  0  1  2  3   4   5    6    7     8
my @Catalan_number     = (1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862, 16796,
                          58786, 208012, 742900);

# A014137             n = 0  1  2  3   4   5    6    7     8
my @Catalan_cumulative = (1, 2, 4, 9, 23, 65, 197, 626, 2056, 6918, 23714,
                          82500, 290512, 208012);

sub factorial {
  my ($n) = @_;
  my $ret = 1;
  foreach my $i (2 .. $n) {
    $ret *= $i;
  }
  return $ret;
}

sub binomial {
  my ($n,$k) = @_;
  if ($n < 0 || $k < 0) { return 0; }
  my $ret = 1;
  foreach my $i (1 .. $k) {
    $ret *= $n-$k+$i;
    ### assert: $ret % $i == 0
    $ret /= $i;
  }
  return $ret;
}
foreach my $n (0 .. 6) {
  foreach my $k (0 .. $n) {
    ok (binomial($n,$k), factorial($n)/factorial($n-$k)/factorial($k),
       "binomial $n,$k");
  }
}
ok (binomial(-1,-1), 0);


#------------------------------------------------------------------------------
# insert

# {
#   my @ret = Graph::Maker::CatalansUpto::_rel_type_insert([1,1,0,0]);
#   ### @ret
#   exit;
# }


#------------------------------------------------------------------------------
# below

{
  my @ret = Graph::Maker::CatalansUpto::_rel_type_below([]);
  ok (scalar(@ret), 1);
}
{
  # directed
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans_upto', N => $N,
                                  rel_type => 'below');
    ok (scalar($graph->vertices), $Catalan_cumulative[$N]);

    # ok (MyGraphs::Graph_num_intervals($graph), rotate_num_intervals($N),
    #     "rotate num_intervals N=$N");

    foreach my $v ($graph->vertices) {
      my $k = length($v)/2;
      ok ($graph->out_degree($v),  $k==$N ? 0 : $k+1);
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
