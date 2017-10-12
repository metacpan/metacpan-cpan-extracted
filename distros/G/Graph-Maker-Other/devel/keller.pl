#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use Math::BaseCnv 'cnv';
use Graph::Maker::Keller;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;


# uncomment this to run the ### lines
# use Smart::Comments;

{
  my $graph = Graph::Maker->new('Keller', N => 3, subgraph=>1,
                                undirected => 1,
                               );
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  print "vertices $num_vertices edges $num_edges\n";
  # print '',(4**$k)*(4**$k-1)/2 - $num_edges,"\n";

  require Graph::Reader::Graph6;
  my $reader = Graph::Reader::Graph6->new;
  my $lace = $reader->read_graph('/so/hog/graphs/graph_6580.g6');
  $num_vertices = $lace->vertices;
  $num_edges = $lace->edges;
  print "vertices $num_vertices edges $num_edges\n";

  print Graph_is_subgraph($graph, $lace);
  exit 0;
}

{
  # Keller vertex neighbours induced subgraph
  # N=3 34 vertices hog not

  #              0 1 2   3    4
  # num vertices 0 0 5  34  171 776
  # num vertices            171, 776, 3351, 14190
  # not in OEIS, apparently
  #
  # num edges    0 0 0 261 9435 225990

  # 0 0 1 1
  # 0 0 1 3
  #      =2

  #         p     q
  # . . . . 2 . . . . .
  # . . . . . . . 2 . .
  #
  # p other       0    13   2
  # q other   0  2,2  1,2  0,2   p rem not all zeros
  #          13  2,1  1,1  0,1   \ p satisfied
  #           2  2,0  1,0  0,0   / so rem arbitrary
  #                   \------/
  #                    q satis
  #
  # N-2 positions not all zero diffs

  # if p=2,0 and q=2,013 then other digits
  # if p=2,2 and q=2,2 then N-2 edge of arbitrary

  my @graphs;
  foreach my $k (0 .. 4) {
    my $graph = Graph::Maker->new('Keller', N => $k, subgraph=>1,
                                  undirected => 1,
                                 );
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    print "vertices $num_vertices edges $num_edges\n";
    # print '',(4**$k)*(4**$k-1)/2 - $num_edges,"\n";
    push @graphs, $graph;
  }
  hog_searches_html(@graphs);
  exit 0;
}

{
  # N=2 Clebsch Graph
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=975
  # N=3 https://hog.grinvin.org/ViewGraphInfo.action?id=22730
  # N=4 
  #
  # edges
  # 0, 0, 40, 1088, 21888, 397312
  #  is 2*A052845 for the first few terms only
  # no diff=2 is 0,1,3 everywhere 3^k
  # diff=2 and no others is (k-1)
  # non-edges 
  # vector(7,k,k++; (4^k*(        (3^k+k-1)))/2)
  # edges
  # vector(7,k,k++; (4^k*(4^k-1 - (3^k+k-1)))/2)
  # vector(7,k,k++; (4^k*(4^k - 3^k - k))/2)
  # vector(7,k,k++; 4^k - 3^k - k)
  # 
  # non-edges
  # 0 6 80 1536 28800 498176
  # not in OEIS apparently

  # 2 positions, one diff by 2, one diff by 1,2,3
  # 21, 22, 23  12, 13
  # vector(7,N,N++; 5*binomial(N,2) * 4^(N-2))  \\ wrong
  #
  # lowest diff by 2 at l, same below
  #    next diff at n, same up to it
  # lowest diff by 1or3 at l, same below
  #    next diff at n by 2, any 0,1,3 up to it
  # vector(7,N,N++; sum(l=0,N-2, 3*sum(n=l+1,N-1, 4^(N-1-n))) \
  #            +  2*sum(l=0,N-2, sum(n=l+1,N-1, 3^(n-1-l) * 4^(N-1-n))))
  #
  # lowest diff by 2 at p, 3^(p-1)-1 below and 4^(N-1-p) above
  #                    or  1         below and 4^(N-1-p)-1 above
  # vector(7,N,N++; sum(p=0,N-1, (3^p-1)*4^(N-1-p) + 4^(N-1-p)-1))
  #
  # lowest diff by 2 at p, 3^(p-1) below and 4^(N-1-p) above
  #                        except not all zeros
  # vector(7,N,N++; sum(p=0,N-1, 3^p*4^(N-1-p) + 1))

  require Graph::Maker::Keller;
  my @graphs;
  foreach my $k (0 .. 4) {
    my $graph = Graph::Maker->new('Keller', N => $k,
                                  subgraph => 0,
                                  undirected => 1,
                                 );
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    print "$num_vertices vertices $num_edges edges\n";
    # print '',(4**$k)*(4**$k-1)/2 - $num_edges,"\n";
    push @graphs, $graph;
  }
  hog_searches_html(@graphs);
  exit 0;
}

{
  # clique number
  foreach my $N (0 .. 5) {
    foreach my $subgraph (1, 0) {
      my $graph = Graph::Maker->new('Keller', N=>$N,
                                    subgraph=>$subgraph,
                                    undirected => 1);
      my $num_vertices = $graph->vertices;
      my $num_edges = $graph->edges;
      my $s = ($subgraph ? 'subgraph' : 'whole');
      print "N=$N $s vertices $num_vertices edges $num_edges\n";
      my $clique_number = Graph_clique_number($graph);
      print "  clique number $clique_number\n";
    }
    print "\n";
  }
  exit 0;
}
{
  # clique number
  require Graph::Maker::Complete;
  my $complete = Graph::Maker->new('complete', N=>5, undirected => 1);
  print Graph_clique_number($complete),"\n";
  exit 0;
}



{
  my $graph = Graph::Maker->new('Keller', N => 3, subgraph=>1,
                                undirected => 1,
                               );
  Graph_view($graph);
  exit 0;
}

{
  # edges base 4

  require Graph::Maker::Keller;
  my $k = 3;
  my $graph = Graph::Maker->new('Keller', N => $k, undirected => 1);
  my @edges = $graph->edges;
  @edges = map { my($from,$to) = @$_;
                 $from = cnv($from,10,4);
                 $to = cnv($to,10,4);
                 sprintf '%0*s-%0*s', $k,$from, $k,$to
               } @edges;
  @edges = sort @edges;
  print "num edges ".scalar(@edges)."\n";
  $, = "\n";
  print @edges,'';
  exit 0;
}


