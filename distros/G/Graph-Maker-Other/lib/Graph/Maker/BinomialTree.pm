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

package Graph::Maker::BinomialTree;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 7;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

sub init {
  my ($self, %params) = @_;

  my $N     = delete($params{'N'});
  my $order = delete($params{'order'});
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);

  my $limit;
  if (! defined $N) {
    $limit = 2**$order - 1;
    $graph->set_graph_attribute (name => "Binomial Tree, order $order");
  } else {
    $limit = $N-1;
    if ($N <= 0) {
      $graph->set_graph_attribute (name => "Binomial Tree, empty");
    } else {
      $graph->set_graph_attribute (name => "Binomial Tree, 0 to $limit");
    }
  }

  ### $limit
  if ($limit >= 0) {
    $graph->add_vertex(0);
    my $directed = $graph->is_directed;

    foreach my $i (1 .. $limit) {
      my $parent = $i & ~($i ^ ($i-1));  # clear lowest 1-bit
      ### edge: "$parent down to $i"
      $graph->add_edge($parent, $i);
      if ($directed) { $graph->add_edge($i, $parent); }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('binomial_tree' => __PACKAGE__);
1;

__END__

=for stopwords Ryde undirected Viswanathan Iyer Udaya Kumar Reddy Wiener subtrees OEIS Intl Math Engg

=head1 NAME

Graph::Maker::BinomialTree - create binomial tree graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::BinomialTree;
 $graph = Graph::Maker->new ('binomial_tree', N => 32);

=head1 DESCRIPTION

C<Graph::Maker::BinomialTree> creates a C<Graph.pm> graph of a binomial tree
with N vertices.  Vertices are numbered from 0 at the root through to N-1.

The parent of vertex n is that n with its lowest 1-bit cleared to 0.
Conversely the children of a vertex n=xx1000 are xx1001, xx1010, xx1100, so
each trailing 0 bit changed to a 1, provided that does not exceed the
maximum N-1.  At the root the children are single bit powers-of-2 up to the
high bit of the maximum N-1.

          __0___
         /  |   \        N => 8
        1   2    4
            |   / \
            3  5   6
                   |
                   7

=head2 Order

The C<order> parameter is another way to specify the number of vertices.
A tree of order=k has N=2^k many vertices.  Such a tree has depth levels 0
to k.  The number of vertices at depth d is the binomial coefficient
binom(k,d), hence the name of the tree.

The N=8 example above is order=3 and the number of vertices at each depth is
1,3,3,1 which are binomials (3,0) to (3,3).

=for GP-Test  binomial(3,0) == 1

=for GP-Test  binomial(3,1) == 3

=for GP-Test  binomial(3,2) == 3

=for GP-Test  binomial(3,3) == 1

A top-down definition is order k tree is two copies of k-1, one at the root
and the other a child of that root.  In the N=8 order=3 example above, 0-3
is an order=2 and 4-7 is another, with 4 starting as a child of the root 0.

A bottom-up definition is order k tree as order k-1 with a new leaf vertex
added to each existing vertex.  The vertices of k-1 with an extra low 0-bit
become the evens of k.  An extra low 1-bit is the new leaves.

Binomial tree order=5 appears on the cover of Knuth "The Art of Computer
Programming", volume 1, "Fundamental Algorithms", second edition.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('binomial_tree', key =E<gt> value, ...)>

The key/value parameters are

    N           =>  integer
    order       =>  integer
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

C<N> is the number of vertices, 0 to N-1.  Or instead C<order> gives
N=2^order many vertices.

Like C<Graph::Maker::BalancedTree>, if the graph is directed (the default)
then edges are added both up and down between each parent and child.  Option
C<undirected =E<gt> 1> creates an undirected graph and for it there is a
single edge from parent to child.

=back

=head1 FORMULAS

=head2 Wiener Index

The Wiener index of the binomial tree is calculated in

=over

K. Viswanathan Iyer and K. R. Udaya Kumar Reddy, "Wiener index of
Binomial Trees and Fibonacci Trees", Intl J Math Engg with Comp, 2009.
arxiv:0910.4432

=back

For order k it is

                (k-1)*4^k + 2^k
    Wiener(k) = ---------------  = 0, 1, 10, 68, 392, ...  (A192021)
                       2

=cut

#      __0      order=2 total path=2*10 = 20
#     /  |
#    1   2
#        |
#        3
#
# GP-DEFINE  Wiener(k) = ( (k-1)*4^k + 2^k ) /2;
# GP-Test  Wiener(0) == 0
# GP-Test  Wiener(1) == 1    \\ 2 vertices, path=1
# GP-Test  Wiener(2) == 10
# GP-Test  Wiener(3) == 68
# GP-Test  Wiener(4) == 392

=pod

The Wiener index is total distance between pairs of vertices, so the mean
distance is, with binomial to choose 2 among the 2^k vertices,

                     Wiener(k)                k
   MeanDist(k) = ---------------- =  k-1 + -------      for k>=1
                 binomial(2^k, 2)          2^k - 1

=cut

# GP-DEFINE  num_vertices(k) = 2^k;
# GP-Test  num_vertices(0) == 1
# GP-Test  num_vertices(2) == 4
#
# GP-DEFINE  MeanDist(k) = Wiener(k) / binomial(num_vertices(k),2);
# GP-DEFINE  MeanDist_simplified(k) = k-1 + k / (2^k-1);
# GP-Test  vector(100,k, MeanDist_simplified(k)) == vector(100,k, MeanDist(k))

=pod

The tree for kE<gt>=1 has diameter 2*k-1 between ends of the deepest and
second-deepest subtrees of the root.  The mean distance as a fraction of the
diameter is then

    MeanDist(k)    1       1              1
    ----------- = --- - ------- + -------------------
    diameter(k)    2    4*k - 4   (2 - 1/k) * (2^k-1)

                -> 1/2  as k->infinity

=cut

# GP-DEFINE  diameter(k) = 2*k-1;
# GP-Test  diameter(2) == 3
# GP-Test  diameter(3) == 5
#
# GP-DEFINE  MeanDist_over_diameter(k) = MeanDist(k) / diameter(k);
# GP-DEFINE  MeanDist_over_diameter_simplified(k) = \
# GP-DEFINE    1/2 - 1/(4*k - 2) + 1 /( (2 - 1/k) * (2^k-1) );
# GP-Test  vector(100,k, MeanDist_over_diameter_simplified(k)) == vector(100,k, MeanDist_over_diameter(k))
# GP-Test  my(k=100000); abs(MeanDist_over_diameter(k) - 1/2) < 1e-5
# binomial_mean -> 1/2
#

=pod

=head2 Independence and Domination

From the bottom-up definition above, a tree of even N has a perfect
matching, being each odd n which is a leaf and its even attachment.  An odd
N has a near-perfect matching (one vertex left over).

The independence number is found by starting with each leaf in an
independent set and its attachment vertex not.  Per the bottom-up definition
this is all vertices.  If N odd then the unpaired existing even vertex can
be included too, for independence number ceil(N/2).

The domination number similarly, by starting each leaf not in the dominating
set and its attachment vertex in the set.  Again this is all vertices so
domination number floor(N/2), except N=1 domination number 1.

=head1 HOUSE OF GRAPHS

House of Graphs entries for the trees here include

=over

=item order=0, L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310>  (single vertex)

=item order=1, L<https://hog.grinvin.org/ViewGraphInfo.action?id=19655>  (path-2)

=item order=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=594>  (path-4)

=item order=3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=700>

=item order=5, L<https://hog.grinvin.org/ViewGraphInfo.action?id=21088>

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
these graphs include

=over

L<http://oeis.org/A192021> (etc)

=back

    A192021   Wiener index

=for GP-Test  vector(7,k,k--; Wiener(k)) == [0, 1, 10, 68, 392, 2064, 10272]

=cut

# k=0 N=1 vertex   W=0
# k=1 N=2 vertices W=1
# k=2 N=4 vertices path, W=3+2+1 + 2+1 + 1 = 10

=pod

=head1 SEE ALSO

L<Graph::Maker>, L<Graph::Maker::BalancedTree>

=head1 LICENSE

Copyright 2015, 2016, 2017 Kevin Ryde

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
