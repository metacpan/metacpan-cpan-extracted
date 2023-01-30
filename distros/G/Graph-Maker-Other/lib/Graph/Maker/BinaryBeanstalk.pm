# Copyright 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde
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

package Graph::Maker::BinaryBeanstalk;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 19;
@ISA = ('Graph::Maker');


# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}
sub _make_graph {
  my ($self, %params) = @_;
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%params);
}
sub _add_edge_reverse {
  my ($graph, $u, $v) = @_;
  $graph->add_edge($v,$u);    # reverse
}
my %add_edge_method = (smaller => \&_add_edge_reverse,
                       parent  => \&_add_edge_reverse,
                       bigger  => 'add_edge',
                       child   => 'add_edge',
                       both    => 'add_cycle');

sub init {
  my ($self, %params) = @_;

  my $height          = delete($params{'height'});
  my $N               = delete($params{'N'});
  my $direction_type  = delete($params{'direction_type'}) || 'both';
  my $graph = $self->_make_graph(%params);

  if ((defined $height && $height > 0)
      || (defined $N && $N > 0)) {
    $graph->add_vertex(0);

    my $add_edge = ($graph->is_undirected ? 'add_edge'
                    : $add_edge_method{$direction_type}
                    || croak "Unrecognised direction_type ",$direction_type);
    my $row_start = 0;
    my $v = 1;
    my $h = 1;
    for (;;) {
      my $parent = $v - _count_1_bits($v);
      ### at: "$v parent $parent  h=$h"
      if ($parent >= $row_start) {
        $row_start = $v;

        $h++;
        if (defined $height && $h > $height) {
          # stop for height limit
          $graph->set_graph_attribute(name=>"Binary Beanstalk, Height $height");
          last;
        }
      }
      if (defined $N && $v >= $N) {
        # stop for N limit
        $graph->set_graph_attribute (name => "Binary Beanstalk, $N Vertices");
        last;
      }

      $graph->$add_edge($parent, $v);
      $v++;
    }
  } else {
    $graph->set_graph_attribute (name => "Binary Beanstalk, Empty");
  }
  return $graph;
}

sub _count_1_bits {
  my ($n) = @_;
  my $count = 0;
  while ($n) {
    $count += ($n & 1);
    $n >>= 1;
  }
  return $count;
}

Graph::Maker->add_factory_type('binary_beanstalk' => __PACKAGE__);
1;

__END__

__END__

=for stopwords Ryde OEIS undirected childful

=head1 NAME

Graph::Maker::BinaryBeanstalk - create binary beanstalk graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::BinaryBeanstalk;
 $graph = Graph::Maker->new ('binary_beanstalk', height => 4);

=head1 DESCRIPTION

C<Graph::Maker::BinaryBeanstalk> creates C<Graph.pm> graphs of the binary
beanstalk per OEIS A179016 etc.

           0
           |
           1       height => 8  rows
          / \
         2   3
            / \
           4   5
          / \
         6   7
            / \
           8   9
         /  \
       10    11
      / \    / \
    12  13  14  15

Vertices are integers starting at root 0.  Vertex n has

    parent(n) = n - CountOneBits(n)
              = 0,0,1,1,3,3,4,4,7,7,8,8,,... (A011371)

For example 9 = 1001 binary has 2 1-bits so parent 9-2=7.

=cut

# GP-DEFINE  parent(n) = n - hammingweight(n);
# GP-Test  vector(16,n,n--; parent(n)) == \
# GP-Test    [0,0,1,1,3,3,4,4,7,7,8,8,10,10,11,11]  /* parent each */
# GP-Test  vector(12,n,n--; parent(n)) == [0,0,1,1,3,3,4,4,7,7,8,8]
# GP-Test  parent(9) == 7

=pod

Other than the root 0, each vertex has 0 or 2 children, hence "binary"
beanstalk.  There are 2 children (not 1) since if even n has parent
n-CountOneBits(n)=p then the next vertex n+1 is same

    parent(n+1) = n+1 - CountOneBits(n+1)
                = n+1 = (CountOneBits(n) + 1)    since n even
                =  p

There are no more than 2 children since the next even n+2 has 1-bit count

    CountOneBits(n+2) <= CountOneBits(n) + 1
    equality when n==0 mod 4, otherwise less

due to flipping run of 1-bits at second lowest bit position.  So parent(n+2)
E<gt>= n+2 - (CountOneBits(n)+1) = p+1, so not the same parent p of n.

=cut

# GP-Test  binary(14) == [1,1,1,0]
# GP-Test  vector(100,n,n*=2; parent(n+1)==parent(n)) == \
# GP-Test  vector(100,n, 1)
# GP-Test  vector(100,n,n*=2; parent(n+2)!=parent(n)) == \
# GP-Test  vector(100,n, 1)
# GP-Test  vector(100,n,n*=2; hammingweight(n+2) <= hammingweight(n)+1) == \
# GP-Test  vector(100,n, 1)

=pod


This also means parent p is always increasing, and therefore the vertices in
a given row are contiguous integers.  That's so of the single vertex row 1
and thereafter remains so by parent number increasing.

The childful vertices in a given row (those which have children) are not
always contiguous.  The first gap occurs at depth 36 where the vertices
116,117,119 have children and 118 does not.

           /-----^------\
          112          113
        /     \       /   \
      116      117   118  119         <-- depth=36
     /   \    /   \      /   \
    120 121  122 123    124 125

=cut

# GP-DEFINE  depth(n) = my(ret=0); while(n,ret++;n=parent(n)); ret;
# GP-Test  vector(5,n,n--; depth(n)) == [0,1,2,2,3]
# GP-Test  vector(4,n,n+=115; depth(n)) == [36,36,36,36]
# GP-Test  vector(6,n,n+=119; parent(n)) == [116,116, 117,117, 119,119]

=head2 Options

C<height> specifies the height of the tree, as number of rows.  Height 1 is
the root alone, height 2 is two rows being vertices 0 and 1, etc.

C<N> specifies how many vertices, being vertex numbers 0 to N-1 inclusive.

If both C<height> and C<N> are given then the tree stops at whichever
C<height> or C<N> comes first.  Since vertex numbers in a row are
contiguous, specifying height is equivalent to an N = first vertex number of
the row after = 1, 2, 4, 6, 8, ... (OEIS A213708).

The default is a directed graph with edges both ways between vertices (like
most C<Graph::Maker> directed graphs).  This is parameter C<direction_type
=E<gt> 'both'>.

Optional C<direction_type =E<gt> 'bigger'> or C<'child'> gives edges
directed to the bigger vertex number, so from smaller to bigger.  This means
parent down to child.

Option C<direction_type =E<gt> 'smaller'> or C<'parent'> gives edges
directed to the smaller vertex number, so from bigger to smaller.  This is
from child up to parent.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new ('binary_beanstalk', key =E<gt> value, ...)>

The key/value parameters are

    height      => integer
    N           => integer
    direction_type => string, "both" (default), 
                        "bigger", "smaller", "parent, "child"
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added as described in
L</Options> above.  Option C<undirected =E<gt> 1> is an undirected graph and
for it there is always a single edge between parent and child.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310> (etc)

=back

    1310       N=1 (height=1), singleton
    19655      N=2 (height=2), path-2
    32234      N=3,            path-3
    500        N=4 (height=3), star-4, claw
    30         N=5,            fork
    334        N=6 (height=4), H graph
    714        N=7
    502        N=8 (height=5)
    60         N=13

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this tree include

=over

L<http://oeis.org/A179016> (etc)

=back

    A011371    parent vertex, n-CountOneBits(n)
    A213723    child vertex, smaller
    A213724    child vertex, bigger

    A071542    depth of vertex
    A213706    depth of vertex, cumulative
    A213708    first vertex in row
    A173601    last vertex in row
    A086876    row width (run lengths of depth)

    A055938    leaf vertices
    A005187    non-leaf vertices
    A179016    trunk vertices
    A213712    trunk increments, = count 1-bits of trunk vertex
    A213719    trunk vertex predicate 0,1
    A213729    trunk vertices mod 2
    A213728    trunk vertices mod 2, flip 0<->1
    A213732    depths of even trunk vertices
    A213733    depths of odd trunk vertices
    A213713    non-trunk vertices
    A213717    non-trunk non-leaf vertices
    A213731    0=leaf, 1=trunk, 2=non-trunk,non-leaf
    A213730    start of non-trunk subtree
    A213715    trunk position within non-leafs
    A213716    non-trunk position within non-leafs
    A213727    num vertices in subtree under n (inc self), or 0=trunk
    A213726    num leafs in subtree under n (inc self), or 0=trunk
    A257126    nth leaf - nth non-leaf
    A257130    new high positions of nth leaf - nth non-leaf
    A218254    paths to root 0
    A213707     positions of root 0 in these paths

    A218604    num vertices after trunk in row
    A213714    how many non-leaf vertices precede n
    A218608    depths where trunk is last in row
    A218606    depths+1 where trunk is last in row
    A257265    depth down to a leaf, minimum
    A213725    depth down to a leaf, maximum in subtree

    A218600    depth of n=2^k-1
    A213709    depth levels from n=2^k-1 to n=2^(k+1)-1
    A213711    how many n=2^k-1 blocks preceding given depth
    A213722    num non-trunk,non-leaf v between 2^n <= v < 2^(n+1)

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::BinomialTree>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde

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
