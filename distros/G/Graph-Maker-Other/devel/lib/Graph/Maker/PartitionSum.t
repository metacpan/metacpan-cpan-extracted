#!/usr/bin/perl -w

# Copyright 2018, 2019, 2020, 2021 Kevin Ryde
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

plan tests => 141;

use FindBin;
use lib "$FindBin::Bin/../..";

# uncomment this to run the ### lines
# use Smart::Comments;

require Graph::Maker::PartitionSum;


#------------------------------------------------------------------------------
{
  my $want_version = 18;
  ok ($Graph::Maker::PartitionSum::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::PartitionSum->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::PartitionSum->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::PartitionSum->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# _partition_next()

# vecsort(apply(Vec,partitions(7)))
{
  my @want = ([ [] ],
              [ [1] ],
              [ [1,1], [2] ],
              [ [1,1,1], [1,2], [3] ],
              [ [1,1,1,1], [1,1,2], [1,3], [2,2], [4] ],
              [ [1,1,1,1,1], [1,1,1,2], [1,1,3], [1,2,2], [1,4], [2,3], [5] ],
              [ [1,1,1,1,1,1], [1,1,1,1,2], [1,1,1,3], [1,1,2,2], [1,1,4],
                [1,2,3], [1,5], [2,2,2], [2,4], [3,3], [6] ],
              [ [1,1,1,1,1,1,1], [1,1,1,1,1,2], [1,1,1,1,3], [1,1,1,2,2],
                [1,1,1,4], [1,1,2,3], [1,1,5], [1,2,2,2], [1,2,4], [1,3,3],
                [1,6], [2,2,3], [2,5], [3,4], [7]],
             );
  foreach my $n (0 .. $#want) {
    ### $n
    my @part = (1) x $n;
    my $want_last = $#{$want[$n]};
    foreach my $i (0 .. $want_last) {
      ### at: "n=$n i=$i"
      ok (join(',',@part), join(',',@{$want[$n]->[$i]}),
          "_partition_next() n=$n i=$i parts");

      my $more = Graph::Maker::PartitionSum::_partition_next(\@part);
      ### more: "i=$i want_last=$want_last got more=$more  part=".join(',',@part)
      ok ($more, $i<$want_last?1:0,
          "_partition_next() n=$n i=$i more");
    }
    # my $more = Graph::Maker::PartitionSum::_partition_next(\@part);
    # ok ($more, 0, "_partition_next() no more")
  }
}

# vector(20,n,n--; numbpart(n))
{
  my @want = (1, 1, 2, 3, 5, 7, 11, 15, 22, 30, 42, 56, 77, 101, 135, 176, 231,
              297, 385, 490);
  foreach my $n (0 .. $#want) {
    my @part = (1) x $n;
    my $count = 0;
    do {
      $count++;
    } while (Graph::Maker::PartitionSum::_partition_next(\@part));
    ok ($count, $want[$n], "_partition_next() num partitions");
  }
}


#------------------------------------------------------------------------------
# Sizes

# OEIS A000041 num partitions
#                    N = 0  1  2
my @want_num_vertices = (1, 1, 2, 3, 5, 7, 11, 15, 22, 30, 42, 56, 77, 101);

# OEIS A000097 partitions choose 2 terms
#                 N = 0  1  2
my @want_num_edges = (0, 0, 1, 2, 5, 9, 17, 28, 47, 73, 114, 170, 253);

foreach my $N (0 .. 8) {
  my $graph = Graph::Maker->new('partition_sum',
                                N => $N,
                                undirected => 1);
  ok (scalar($graph->vertices), $want_num_vertices[$N],
      "N=$N num vertices");
  ok (scalar($graph->edges), $want_num_edges[$N],
      "N=$N num edges");
  ok ($graph->diameter || 0, $N==0 ? 0 : $N-1,
      "N=$N diameter");
}


#------------------------------------------------------------------------------
exit 0;
