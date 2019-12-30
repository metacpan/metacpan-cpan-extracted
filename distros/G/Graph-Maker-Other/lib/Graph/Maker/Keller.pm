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

package Graph::Maker::Keller;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 14;
@ISA = ('Graph::Maker');


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

sub _is_edge {
  my ($from,$to) = @_;
  my $diff = $from ^ $to;
  my $seen_two = 0;
  my $seen_any = 0;
  while ($diff) {
    my $digit = $diff & 3;
    if ($digit)      { $seen_any++; }
    if ($digit == 2) { $seen_two++; }
    if ($seen_any >= 2 && $seen_two) {
      return 1;
    }
    $diff >>= 2;
  }
  return 0;
}

sub init {
  my ($self, %params) = @_;

  my $N        = delete($params{'N'}) || 0;
  my $subgraph = delete($params{'subgraph'}) || 0;
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);
  my $add_edge = ($graph->is_directed ? 'add_cycle' : 'add_edge');

  if ($subgraph) {
    $graph->set_graph_attribute (name => "Keller Subgraph $N");

    my @vertices;
    foreach my $to (1 .. (1 << (2*$N))-1) {
      if (_is_edge(0,$to)) {
        $graph->add_vertex($to);
        push @vertices, $to;
      }
    }
    foreach my $i (0 .. $#vertices) {
      my $from = $vertices[$i];
      foreach my $j ($i+1 .. $#vertices) {
        my $to = $vertices[$j];
        if (_is_edge($from,$to)) {
          $graph->$add_edge($from, $to);
        }
      }
    }

  } else {
    $graph->set_graph_attribute (name => "Keller $N");

    my $max_vertex = (1 << (2*$N)) - 1;
    for my $from (0 .. $max_vertex) {
      $graph->add_vertex($from);  # for $N < 2 where there are no edges

      for my $to ($from+1 .. $max_vertex) {
        if (_is_edge($from,$to)) {
          $graph->$add_edge($from, $to);
        }
      }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('Keller' => __PACKAGE__);
1;





    # for (my($i,$imask) = (0,1);
    #      $i < $N;
    #      $i++, $imask <<= 2) {
    #   foreach my $ixor ($imask, 2*$imask, 3*$imask) {
    #     my $in = $n ^ $ixor;
    #     
    #     for (my($j,$jmask) = (0,2);
    #          $j < $N;
    #          $j++, $jmask <<= 2) {
    #       next if $i == $j;
    #       
    #       my $n2 = $in ^ $jmask;
    #       if ($directed || $n2 > $n) {
    #         $graph->add_edge($n, $n2);
    #       }
    #     }
    #   }
    # }


__END__

=for stopwords Ryde Keller cyclotomic tilings hypercubes Clebsch Subgraph subgraph undirected OEIS Uber luckenlose Einfullung des Raumes mit Wurfeln Reine und Angewandte Mathematik Crelle DIMACS

=head1 NAME

Graph::Maker::Keller - create Keller graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Keller;
 $graph = Graph::Maker->new ('Keller', N => 2);

=head1 DESCRIPTION

C<Graph::Maker::Keller> creates a C<Graph.pm> graph of a Keller graph.  This
is a graph form of Keller's conjecture on N-dimensional tilings by unit
hypercubes.

The Keller graph N has 4^N vertices numbered 0 to 4^N-1.  These vertices are
treated as base-4 integers.  Edges are between vertices differing in 2 or
more digit positions, at least one of which is difference = 2 mod 4.

    N         0  1   2     3      4       5
    vertices  1, 4, 16,   64,   256,   1024, ...  4^N
    degree    0, 0,  5,   34,   171,    776, ...  4^N - 3^N - N
    edges     0, 0, 40, 1088, 21888, 397312, ... (4^N-3^N-N)*4^N / 2

Each vertex has the same degree (so a regular graph) since digit differences
can all be taken mod 4.  Each vertex degree is 4^N - 3^N - N.  This is edges
to 4^N vertices (including self) except no edge to those differing by only
0,1,3 in any or all digit positions, which is 3^N combinations (including no
differences at all for vertex itself), and also no edge to vertices
differing by 2 mod 4 at a single digit, which is N possible digit positions.

=for GP-Test  vector(6,N,N--; 4^N-3^N-N) == [0, 0, 5, 34, 171, 776]

=for GP-Test  vector(6,N,N--; 1/2*4^N*(4^N-3^N-N)) == [0, 0, 40, 1088, 21888, 397312]

=for GP-Test  vector(6,N,N--; 1/2*4^N*(4^N-1) - 1/2*4^N*(4^N-3^N-N)) == [0, 6, 80, 928, 10752, 126464]

N=0 and N=1 have no edges since there are only 0 digits and 1 digit
respectively, so nothing differs in 2 digit positions.

N=2 (16 vertices and 40 edges) is the Clebsch graph, which is the
16-cyclotomic graph.

=head2 Subgraph

C<subgraph =E<gt> 1> gives the subgraph of the Keller graph induced by
neighbours of vertex 0.  This means the neighbours of vertex 0 (and not 0
itself) and the edges among those neighbours.

    subgraph => 1
    N         0  1   2     3      4       5
    vertices  0, 0,  5,   34,   171,    776, ... 4^N - 3^N - N
    edges     0, 0,  0,  261,  9435, 225990, ...

=cut

# 171, 776, 3351, 14190
# not in OEIS, apparently

=pod

The number of vertices is the degree above.  This subgraph is of interest
since the Keller graph is vertex transitive and so the problem of finding a
clique of size k in the Keller graph is reduced to finding a clique of size
k-1 in this subgraph.  The size of the maximum clique is related to Keller's
conjecture.

N=2 subgraph has no edges.  Its vertices are 12, 21, 22, 23, 32 in base-4
and any pair of them either differ in only 1 digit or differ in 2 digits but
without a difference 2 mod 4.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Keller', key =E<gt> value, ...)>

The key/value parameters are

    N           => integer
    subgraph    => 0 or 1, default 0
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both forward and
backward between vertices.  Option C<undirected =E<gt> 1> creates an
undirected graph and for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310> (etc)

=back

    1310     N=0  (singleton)
    52       N=1  (4 singletons)
    975      N=2  (Clebsch, 16-cyclotomic)
    34165    N=3

And C<subgraph> option

    62       N=2  (5 singletons)
    22730    N=3
    22732    N=4

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
these graphs include

=over

L<http://oeis.org/A202604> (etc)

=back

    A202604    clique numbers (size of maximum clique)

=head1 SEE ALSO

L<Graph::Maker>

O. H. Keller, "Uber die luckenlose Einfullung des Raumes mit Wurfeln",
Journal fE<252>r die Reine und Angewandte Mathematik (Crelle's journal),
volume 163, 1930, pages 231-248.

The second DIMACS challenge 1993 included the N=4 subgraph among its
benchmarks for comparing clique-finding algorithms,
L<http://dimacs.rutgers.edu/Challenges/>

=cut

# in their binary form,
# ftp://dimacs.rutgers.edu/pub/challenge/graph/benchmarks/clique/keller4.clq.b

=pod

=head1 LICENSE

Copyright 2015, 2016, 2017, 2018, 2019 Kevin Ryde

This file is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

This file is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
This file.  If not, see L<http://www.gnu.org/licenses/>.

=cut
