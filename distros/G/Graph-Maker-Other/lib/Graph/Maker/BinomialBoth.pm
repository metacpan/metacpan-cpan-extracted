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


package Graph::Maker::BinomialBoth;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 18;
@ISA = ('Graph::Maker');

# GP-DEFINE  default(strictargs,1);
# GP-DEFINE  read("my-oeis.gp");
# GP-DEFINE  read("memoize.gp");

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}
sub _make_graph {
  my ($params) = @_;
  my $graph_maker = delete($params->{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%$params);
}
sub _add_edge_reverse {
  my ($graph, $u, $v) = @_;
  $graph->add_edge($v,$u);    # reverse
}
my %add_edge_func = (smaller => \&_add_edge_reverse,
                     bigger  => 'add_edge',
                     both    => 'add_cycle');

sub _count_1bits {
  my ($n) = @_;
  my $ret = 0;
  while ($n) { $ret += $n&1; $n >>= 1; }
  return $ret;
}

sub init {
  my ($self, %params) = @_;

  my $order           = delete($params{'order'});
  my $direction_type  = delete($params{'direction_type'}) || 'both';
  my $coordinate_type = delete($params{'coordinate_type'}) || '';
  my $graph           = _make_graph(\%params);

  my $add_edge = ($graph->is_undirected ? 'add_edge'
                  : $add_edge_func{$direction_type}
                  || croak "Unrecognised direction_type ",$direction_type);

  my $limit = (1<<$order) - 1;
  $graph->set_graph_attribute (name => "Binomial Both, Order $order");

  $graph->add_vertex(0);
  my $directed = $graph->is_directed;

  foreach my $i (1 .. $limit) {
    my $from = $i & ~($i ^ ($i-1));  # clear lowest 1-bit
    ### edge: "$from down to $i"
    $graph->$add_edge($from, $i);    # from smaller
  }
  for (my $i = 1; $i < $limit; $i += 2) {  # odds
    my $to = $i | ($i ^ ($i+1));     # set lowest 0-bit
    ### edge: "$to up to $i"
    $graph->$add_edge($i, $to);      # to bigger
  }

  if ($coordinate_type eq 'across') {
    foreach my $i (0 .. $limit) {
      $graph->set_vertex_attribute($i, x => $i>>1);
      $graph->set_vertex_attribute($i, y => - _count_1bits($i));
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('binomial_both' => __PACKAGE__);
1;

__END__

=for stopwords Ryde undirected Apery OEIS Wnew

=head1 NAME

Graph::Maker::BinomialBoth - create binomial both graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::BinomialBoth;
 $graph = Graph::Maker->new ('binomial_both', order => 3,
                             direction_type => 'bigger');

=head1 DESCRIPTION

C<Graph::Maker::BinomialBoth> creates a C<Graph.pm> graph of a "binomial
both" of order k.  This is a binomial tree both upwards and downwards.
Vertices are numbered from 0 up to max = 2^k-1 where k is the "order".

    0----
    | \  \
    1  2  4            order => 3
     \ |  | \          vertices 0 to 7
       3  5  6
        \  \ |
         ----7

Each vertex v is taken as k many bits, including high 0s as necessary.  Each
edge is

    from            to
    ----   -----------------------
     v     clear lowest 1-bit of v       \ edges
     v     set lowest 0-bit of v         /

Clear-lowest-1 is the parent of v in the binomial tree
(L<Graph::Maker::BinomialTree>).  Set-lowest-0 is the same applied towards
the maximum vertex 2^k-1, as if that was the root by everywhere bit flip
0E<lt>-E<gt>1.

Both rules apply at the least significant bit, which is the low bit flipped
0 E<lt>-E<gt> 1.  Just one edge is added for this, by not applying the
set-lowest-0 rule at the low bit.  Consequently there are 2^k-1 edges of
clear-lowest-1 and 2^(k-1)-1 edges of set-lowest-0 for total

    num_edges(k) = / 0                  if k = 0
                   \ 3 * 2^(k-1) - 2    if k >= 1
                 = 0, 1, 4, 10, 22, 46, 94, 190, ...  (A296953)

=cut

# GP-DEFINE  num_edges_formula(k) = 3*2^(k-1) - 2;
# GP-DEFINE  num_edges(k) = if(k==0,0, num_edges_formula(k));
# GP-Test  num_edges_formula(0) == -1/2
# GP-Test  vector(8,k,k--; num_edges(k)) == [0, 1, 4, 10, 22, 46, 94, 190]

=pod

Each edge changes just one bit so binomial both is a sub-graph of hypercube
k (L<Graph::Maker::Hypercube>).

A top-down definition is to make order k from two copies of k-1.  The max of
the first connects down to the max of the second, and the min of the first
connects down to the min of the second.

          min
    first |.| \
          |.|   min
          max   |.| second
              \ |.|
                max

=head2 Direction Type

The default is a directed graph with edges both ways between vertices (like
most C<Graph::Maker> directed graphs).  This is parameter C<direction_type
=E<gt> 'both'>.

Optional C<direction_type =E<gt> 'bigger'> gives edges directed to the
bigger vertex number, so from smaller to bigger.  The result is a graded
lattice (the algebra type of lattice, partially ordered set) with edges its
cover relations.  (The name "binomial lattice" is normally given to the grid
type lattice formed by random share price movements, so here "binomial both"
instead.)

The lattice is graded by d = number of 1-bits in the vertex number, which is
the binomial tree depth.  Like the binomial tree, the number of vertices at
depth d is binomial coefficient binomial(k,d).

Option C<direction_type =E<gt> 'smaller'> gives edges directed to the
smaller vertex number, so from bigger to smaller.  This is the same as
C<$graph-E<gt>transpose()> reversing edges.

=head2 Coordinates

There's a secret undocumented coordinates option the same as the binomial
tree L<Graph::Maker::BinomialTree/Coordinates>.  Don't rely on this yet as
it might change or be removed.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('binomial_both', key =E<gt> value, ...)>

The key/value parameters are

    order          =>  integer >=0
    direction_type =>  string, "both"    (default)
                               "bigger"
                               "smaller"
    graph_maker    =>  subr(key=>value) constructor,
                         default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added as described in
L</Direction Type>.  Option C<undirected =E<gt> 1> creates an undirected
graph and for it there is always a single edge between relevant vertices.

=back

=head1 FORMULAS

=head2 Successors

As a lattice of direction "bigger", the full set of eventually reachable
C<all_successors()> of a vertex v is formed by setting any combination of
its low 0-bits to 1-bits, and setting all those low 0s to 1s plus
successively low to high each other 0 to 1.  For example

    v =  101101100  \
         101101101  |   4 combinations of low 0s
         101101110  |
         101101111  /
         101111111  \   then all low 0s to 1s and
         111111111  /   successively set each other 0

The all-of-low-0s is the max of a sub-lattice containing v.  The successive
other 0s are the path (sole path) from that sub-lattice max to the global
max.  If v has no low 0s then just this path to the global max is all its
reachable successors.

=head2 Maximal Chains

A maximal chain in a lattice is a path from global min to global max.  In
the graph here, this is the number of paths from v=0 to v=2^k-1 in direction
type "bigger".

    num_max_chains(k) = / 1           if k=0
                        \ 2^(k-1)     if k>=1
                     = 1, 1, 2, 4, 8, 16, ...   (A011782)

=cut

# GP-DEFINE  num_max_chains(k) = if(k==0,1, 2^(k-1));
# GP-Test  vector(6,k,k--; num_max_chains(k)) == [1, 1, 2, 4, 8, 16]

=pod

In the top-down definition above, a path can go through the first half or
second half, and then the same recursively in quarters etc until k=1 is 2
vertices and just one path.

=head2 Intervals

An interval in a lattice is a pair of vertices u,v which are comparable.  In
the graph with direction type "bigger", this means one vertex is reachable
from the other by some directed path.  u=v is an interval too.

    num_intervals(k) = k*2^k + 1         Cullen numbers
                     = 1, 3, 9, 25, 65, 161, 385, ...   (A002064)

In the top-down definition, order k formed from two k-1 gives new intervals
from first half min to each second half vertex, and from each of the other
first half vertices to the second half max.  So the following recurrence,
and from which the Cullen numbers,

    num_intervals(k) = 2*num_intervals(k-1) + 2^(k-1) + 2^(k-1) - 1

=cut

# GP-DEFINE  num_intervals(k) = k*2^k + 1;
# GP-Test  vector(8,k,k--; num_intervals(k)) == \
# GP-Test    [1, 3, 9, 25, 65, 161, 385, 897]
# GP-Test  vector(10,k, num_intervals(k)) == \
# GP-Test  vector(10,k, 2*num_intervals(k-1) + 2^(k-1) + 2^(k-1) - 1)

=pod

=head2 Complementary Pairs

A complementary pair in a lattice is two vertices u,v where their meet and
join are the global min and global max.  In the graph with direction type
"bigger", this means C<$u-E<gt>all_predecessors()> and
C<$v-E<gt>all_predecessors()> have only the global minimum (0) in common,
and also C<all_successors()> only the global maximum in common (2^k-1).

    num_complementary(k) = /  1                       if k=0
                           \  (2^(k-1) - 1)^2 + 1     if k>=1
                         = 0, 1, 2, 10, 50, 226, ...  (2*A092440)

This count follows from the top-down definition.  Pairs within a half have
the half min and max in common, only one of those is the global min/max, so
no complementary pairs.  The first half min has all of the second half as
descendants, so only first half min as global smallest and second max as
global biggest are a pair.  Then the other 2^(k-1)-1 vertices of the first
half are complementary to the 2^(k-1)-1 vertices of the second half except
the second max which is the global maximum.  For k=0, the single vertex is a
complementary pair 0,0.

=cut

# GP-DEFINE  num_complementary_formula(k) = (2^(k-1) - 1)^2 + 1;
# GP-DEFINE  num_complementary(k) = if(k==0,1, num_complementary_formula(k));
# GP-Test  vector(6,k,k--; num_complementary(k)) == [1, 1, 2, 10, 50, 226]

=pod

=head2 Wiener Index

The top-down definition means the Wiener index of order k+1 is twice k plus
paths from the first k to the second k.  Those paths go by the top edge or
the bottom edge between the halves, whichever is the shorter way.  So a sum
over depth u in the first, depth v in the second, with respective numbers of
vertices at those depths,

               k   k
    Wnew(k) = sum sum  binomial(k,u) * binomial(k,v)
              u=0 v=0    * min(u+v+1, (k-u)+(k-v)+1)

            = 1, 6, 36, 196, 1000, 4884, 23128, ...

    W(k+1) = 2*W(k) + Wnew(k)           Wiener index
      starting W(k)=0

    W(k) = 0, 1, 8, 52, 300, 1600, 8084, 39296, ...

=cut

# GP-DEFINE  Wnew_by_min(k) = {
# GP-DEFINE    k>=0 || error();
# GP-DEFINE    sum(u=0,k, sum(v=0,k,
# GP-DEFINE      binomial(k,u) * binomial(k,v) * min(u+v+1,(k-u)+(k-v)+1)));
# GP-DEFINE  }
# GP-Test  vector(7,k,k--; Wnew_by_min(k)) == \
# GP-Test    [1, 6, 36, 196, 1000, 4884, 23128]
# vector(10,k,k--; Wnew_by_min(k))
# not in OEIS: 1, 6, 36, 196, 1000, 4884, 23128, 107048, 486864, 2183860
#
# GP-DEFINE  W_by_min(k) = {
# GP-DEFINE    k>=0 || error();
# GP-DEFINE    if(k==0,0, 2*W_by_min(k-1) + Wnew_by_min(k-1));
# GP-DEFINE  }
# GP-DEFINE  W_by_min=memoize(W_by_min);
# GP-Test  vector(9,k,k--; W_by_min(k)) == \
# GP-Test    [0,1,8,52,300,1600,8084,39296,185640]
# vector(10,k, W_by_min(k))
# not in OEIS: 1, 8, 52, 300, 1600, 8084, 39296, 185640, 858144, 3900148

=pod

For comparison, the Wiener index of the binomial tree is this sum but always
u+v+1 instead of min().

=cut

# GP-DEFINE  TreeW(k) = ( (k-1)*4^k + 2^k ) /2;
# vector(9,k,k--; TreeW(k+1) - 2*TreeW(k)) == \
# vector(9,k,k--; (k+1)*4^k)
# GP-DEFINE  gTreeW(x) = x/(1-2*x) * 1/(1 - 4*x)^2;
# GP-Test  sum(k=0,20, x^k*TreeW(k) ) == gTreeW(x + O(x^20))
#
# GP-Test  vector(9,k,k--; TreeW(k+1)) == \
# GP-Test  vector(9,k,k--; 2*TreeW(k) \
# GP-Test    + sum(u=0,k, sum(v=0,k, \
# GP-Test        binomial(k,u) * binomial(k,v) * (u+v+1))) )

=pod

A bottom-up approach in the binomial both is to consider each vertex
duplicating to a new vertex below, like the binomial tree bottom-up
definition.  An existing path between vertices in k becomes 4 paths in k+1.

    top  ......        A  to B  distance L
        |      |       A  to B' distance L+1
        A      B       A' to B  distance L+1
        |      |       A' to B' distance L+2 top way
    new A'     B'                       ----
                                        4L+4

    or if A to B path in k are same distance by top or bottom
    then A' to B' can go the bottom way for distance L and total
                   L + L+1 + L+1 + L  = 4L+2

Each same-distance path in k is between opposite vertices.  For example, the
following is two j=4 blocks with binomial number of vertices at depths a
to e.

    a 1----1 e'
      |    |         paths between
    b 4    4 d'      two j=4 blocks
      |    |
    c 6    6 c'      a to a' distance L=5 either way around
      |    |         b to b' likewise, etc
    d 4    4 b'
      |    |
    e 1----1 a'

The number of vertices at a depth and its opposite is the same
binomial(j,depth) each.  So with 2^(k-j) sub-block pairs of each sub-order
j, each depth i, and binomial*binomial vertices each side, and each of these
paths 2 shorter than the other paths (4L+2 rather than 4L+4),

                                       k           j
    W(k+1) = 4*W(k) + 4*Wpairs(k) - 2*sum 2^(k-j) sum binomial(j,i)^2
                                      j=0         i=0

    Wpairs(k) = binomial(num_vertices(k), 2)
              = 2^k * (2^k-1) / 2
              = 0, 1, 6, 28, 120, 496, 2016, ...      (A006516)

=cut

# GP-DEFINE  num_vertices(k) = 2^k;
# GP-DEFINE  Wpairs(k) = binomial(num_vertices(k),2);
# GP-Test  my(want=OEIS_samples("A006516"));  /* OFFSET=0 */ \
# GP-Test    vector(#want,k,k--; Wpairs(k)) == want
# GP-Test  vector(7,k,k--; Wpairs(k)) == [0, 1, 6, 28, 120, 496, 2016]
# GP-Test  vector(100,k,k--; Wpairs(k)) == \
# GP-Test  vector(100,k,k--; 1/2*( 4^k - 2^k ))
# GP-DEFINE  gWpairs(x) = x/((1 - 2*x)*(1 - 4*x));
# GP-Test  gWpairs(x) == 1/2*( 1/(1-4*x) - 1/(1-2*x) )

=pod

Sum(binomial^2) is the central binomial coefficient binomial(2*j,j).  Its
generating function is 1/sqrt(1 - 4*x).  Working through that with some
usual recurrence or generating function manipulations for a convolution to
multiply 2^(k-j) and accumulate, gives a D-finite recurrence (coefficients
are rational functions of k),

=cut

# GP-DEFINE  \\ central binomial = binomial(2*n,n) = (2*n)!/(n!)^2
# GP-DEFINE  A000984(n) = binomial(2*n,n);
# GP-Test  vector(100,n, A000984(n)) == \
# GP-Test  vector(100,n, sum(j=0,n, binomial(n,j)^2))
# D-finite with recurrence: n*a(n) + 2*(1-2*n)*a(n-1)=0.
# GP-Test  vector(100,n, n*A000984(n)) == \
# GP-Test  vector(100,n, (4*n-2)*A000984(n-1))
#
# GP-DEFINE  gA000984(x) = 1/sqrt(1 - 4*x);
# GP-Test  sum(k=0,20, x^k*A000984(k) ) == gA000984(x + O(x^20))
# GP-Test  vector(20,n,n--; binomial(2*n,n)) == \
# GP-Test  Vec(1/sqrt(1-4*x + O(x^20)))

=pod

            2    /     ( 14*k- 34) * W(k-1)   \
    W(k) = --- * |   - ( 72*k-204) * W(k-2)   |     for k>=4 
           k-2   |   + (160*k-512) * W(k-3)   |
                 \   - (128*k-448) * W(k-4)   /

=cut

# GP-DEFINE  \\ [-1, 2, 14, -72, 160, -128, -34, 204, -512, 448]~
# GP-DEFINE  W(k) = {
# GP-DEFINE    k>=0 || error();
# GP-DEFINE    if(k==0,0, k==1,1, k==2,8, k==3,52,
# GP-DEFINE    1/(k-2) * (  ( 14*k- 34) * W(k-1)
# GP-DEFINE               - ( 72*k-204) * W(k-2)
# GP-DEFINE               + (160*k-512) * W(k-3)
# GP-DEFINE               - (128*k-448) * W(k-4) ) );
# GP-DEFINE  }
# GP-DEFINE  W=memoize(W);
# GP-Test  vector(50,k,k--; W(k)) == \
# GP-Test  vector(50,k,k--; W_by_min(k))

=pod

Or with a power of 4, and a generating function in that style,

            2    /     (3*k-5) * W(k-1)   \
    W(k) = --- * |   - (4*k-6) * W(k-2)   |     for k>=3
           k-2   \   + (  k-3) * 4^(k-2)  /
                 
              x      /     1             2*x      \
    gW(x) = ----- * |  ---------  - -------------  |
            1-2*x    \ (1-4*x)^2    (1-4*x)^(3/2) /

=cut

# GP-DEFINE  W_with_4k(k) = {
# GP-DEFINE    k>=0 || error();
# GP-DEFINE    if(k==0,0, k==1,1, k==2,8,
# GP-DEFINE       2/(k-2)* (  (3*k-5) * W(k-1)
# GP-DEFINE                 - (4*k-6) * W(k-2)
# GP-DEFINE                 + (  k-3) * 4^(k-2) )
# GP-DEFINE      );
# GP-DEFINE  }
# GP-Test  vector(200,k,k+=3; W(k)) == \
# GP-Test  vector(200,k,k+=3; W_with_4k(k))
#
# GP-Test  vector(15,k,k+=3; (8*k-16)   *W_by_min(k)) == \
# GP-Test  vector(15,k,k+=3; (48*k-80)  *W_by_min(k-1) \
# GP-Test                  + (-64*k+96) *W_by_min(k-2) \
# GP-Test                  + (k-3)*4^k )
#
# GP-DEFINE  gW(x) = x/(1-2*x)*( 1/(1-4*x)^2 - 2*x/(1-4*x)^(3/2) );
# GP-Test  sum(k=0,200, x^k*W(k) ) == gW(x + O(x^200))

# diameter k
# W(k) / Wpairs(k) / k -> 1  mean distance between
# for(i=1,16,my(k=2^i); \
#   for(i=1,k,W(i)); /* memoize calc */ \
#   print(W(k)/Wpairs(k)*1.0 / k))

# TreeW(k) / Wpairs(k) / (2*k-1) -> 1/2  mean distance between
# for(i=1,16,my(k=2^i); \
#   print(TreeW(k)/Wpairs(k)*1.0 / (2*k-1)))

=pod

In the generating function, the last term 2*x /(1-4*x)^(3/2) is the Apery
numbers k*binomial(2*k,k) (OEIS A005430).  So without the 1/(1-2*x)
convolution, this gives the Wnew paths as

    Wnew(k) = (k+1)*4^k - k*binomial(2*k,k)

=cut

# GP-DEFINE  Wnew(k) = W(k+1) - 2*W(k);
# GP-Test  vector(50,k,k--; Wnew_by_min(k)) == \
# GP-Test  vector(50,k,k--; Wnew_by_min(k))
# GP-Test  vector(100,k,k--; Wnew(k)) == \
# GP-Test  vector(100,k,k--; (k+1)*4^k - k*binomial(2*k,k))

# GP-DEFINE  Apery(k) = k*binomial(2*k,k);
# GP-Test  my(want=OEIS_samples("A005430"));  /* OFFSET=0 */ \
# GP-Test    vector(#want,k,k--; Apery(k)) == want
# GP-Test  sum(k=0,20, x^k*Apery(k) ) == 2*x /(1-4*x + O(x^20))^(3/2)

=pod

Roughly speaking, this would be 2^k*2^k new paths with average length k+1
but less the binomial term.

=head1 HOUSE OF GRAPHS

House of Graphs entries for the graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310> (etc)

=back

    1310    order=0, single vertex
    19655   order=1, path-2
    674     order=2, 4-cycle
    35455   order=3, cross-connected 4-cycles
    35447   order=4
    35449   order=5
    35451   order=6
    35453   order=7

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to the
graphs here include

=over

L<http://oeis.org/A296953> (etc)

=back

    A296953   num edges
    A011782   num intervals
    A011782   num maximal chains
    A002064   1/2 * num complementary pairs, k>=2

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::BinomialTree>,
L<Graph::Maker::Hypercube>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2019, 2020, 2021 Kevin Ryde

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
