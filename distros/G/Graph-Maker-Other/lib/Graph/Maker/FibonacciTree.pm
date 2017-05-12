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

package Graph::Maker::FibonacciTree;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 6;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;

sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

# require Math::NumSeq::FibonacciWord;
# my $seq = Math::NumSeq::FibonacciWord->new;

sub init {
  my ($self, %params) = @_;

  my $height         = delete($params{'height'}) || 0;
  my $series_reduced = delete($params{'series_reduced'}) ? 1 : 0;
  my $leaf_reduced   = delete $params{'leaf_reduced'};
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  ### FibonacciTree ...
  ### $height

  my $graph = $graph_maker->(%params);

  $graph->set_graph_attribute
    (name => "Fibonacci Tree height $height"
     . ($series_reduced && $leaf_reduced ? ', series and leaf reduced' : '')
     . ($series_reduced ? ', series reduced' : '')
     . ($leaf_reduced ? ', leaf reduced' : ''));

  if ($height > 0) {
    $graph->add_vertex(1);

    my @pending_n     = (1);
    my @pending_depth = (1);
    my @pending_type  = (0);  # left
    my $upto = 1;
    my $directed = $graph->is_directed;

    my $add = sub {
      my ($parent) = @_;
      my $n = ++$upto;
      $graph->add_edge($parent, $n);
      if ($directed) { $graph->add_edge($n, $parent); }
      return $n;
    };

    foreach (2 .. $height) {
      ### at: "row $_"
      ### pending_n: join(',',@pending_n)
      ### pending_depth: join(',',@pending_depth)
      ### pending_type: join(',',@pending_type)

      my @new_pending_n;
      my @new_pending_depth;
      my @new_pending_type;

      while (@pending_n) {
        my $parent = shift @pending_n;
        my $depth = shift @pending_depth;
        my $type = shift @pending_type;
        ### under: "parent=$parent  depth=$depth  type=$type"

        next if $depth >= $height;
        $depth++;

        #         0              0
        #        / \            / \
        #   d+1 0   1 d+1      0   0  d+2
        #      / \  |         / \
        #     0  1  0 d+2    0   0

        # left child
        {
          ### left to: "depth=$depth"
          push @new_pending_n,     $add->($parent);
          push @new_pending_depth, $depth;
          push @new_pending_type,  0; # non-delay
        }

        if ($type == 0) {
          if ($series_reduced && $depth < $height) {
            # series reduced, step down to depth+2
            $depth++;
          } elsif ($leaf_reduced && $depth == $height) {
            # leaf reduced, no node
            next;
          } else {
            $type = 1;
          }
        } else {
          # only single child under a delay
          next;
        }

        ### right to: "depth=$depth"
        push @new_pending_n,     $add->($parent);
        push @new_pending_depth, $depth;
        push @new_pending_type,  $type;  # right
      }

      @pending_n     = @new_pending_n;
      @pending_depth = @new_pending_depth;
      @pending_type  = @new_pending_type;
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('fibonacci_tree' => __PACKAGE__);
1;

__END__



# Harborth and Lohmann "Mosaic Numbers of Fibonacci Trees"
#   Steinhaus style fixed height
#
#                   * *   *
#                   |  \ /
# T3 = *   *   T4=  *   *
#       \ /          \ /
#        *            *
# F(h) on level h, being F(h-1) type A and F(h-2) type B

# Knuth 0 = single node
#       1 = single node
#
# Horibe 1 = single node   = Knuth order+1
#        2 = single node
#
# Nievergelt and Reingold
#    0 = empty
#    1 = single node
#
# Jia and McLaughlin "Balaban's Index"
#    both reduced, tree T1 as single node
#
# Sage 0 = empty
#      1 = single node



  # my $zero_node     = delete $params{'zero_node'};
  # ### $zero_node
  # my $right_stretch = delete $params{'right_stretch'};
  # ### $right_stretch
  # my $order         = delete($params{'order'}) || 0;
  ### $order
  # {
  #   my $upto = 1;
  #   if ($height > 0) {
  #     $graph->add_vertex(1);
  #     my $upto = 1;
  #     my $row_start = 1;
  #     my $row_end = 1;
  #
  #     require Math::NumSeq::FibonacciWord;
  #     my $seq = Math::NumSeq::FibonacciWord->new;
  #
  #     foreach (2 .. $height) {
  #       ### row: "row=$_   $row_start to $row_end"
  #
  #       my $fibbinary = 1;
  #       foreach my $parent ($row_start .. $row_end) {
  #         my ($i, $value) = $seq->next;
  #         # ### assert: ($fibbinary&1) == $value;
  #         print(($fibbinary & 1),$value,"  ");
  #
  #         # 1 or 2 children for $parent
  #         foreach (1 .. (1 + ($fibbinary & 1))) {
  #           $graph->add_edge($parent, ++$upto);
  #         }
  #
  #         my $filled = ($fibbinary >> 1) | $fibbinary;
  #         my $mask = (($filled+1) ^ $filled) >> 1;
  #         $fibbinary = ($fibbinary | $mask) + 1;
  #       }
  #       print "\n";
  #       $row_start = $row_end+1;
  #       $row_end = $upto;
  #     }
  #
  #     ### final row: "$row_start to $row_end"
  #   }
  #   return $graph;
  # }
  #
  # {
  #   my $upto = 1;
  #   if ($order > 0 || $zero_node) { $graph->add_vertex($upto); }
  #   if ($order <= 1) {
  #     return $graph;
  #   }
  #
  #   # breadth-first traversal
  #   my @pending_n = ($upto);
  #   my @pending_order = ($order);
  #   $upto++;
  #   my $directed = $graph->is_directed;
  #
  #   my $add = sub {
  #     my ($parent) = @_;
  #     my $n = ++$upto;
  #     $graph->add_edge($parent, $n);
  #     if ($directed) { $graph->add_edge($parent, $n); }
  #     return $n;
  #   };
  #
  #   while (@pending_n) {
  #     # vertex $n is $order>=2 and is to have below it $order-1 and $order-2
  #
  #     my $n = shift @pending_n;
  #     my $order = shift @pending_order;
  #     ### at: "$n order=$order"
  #     ### pending: join(',',@pending_n)."    ".join(',',@pending_order)
  #
  #     if ($order < 0) {  # right_stretch
  #       $n = $add->($n);
  #       $order = -$order;
  #       if ($order >= 2) {
  #         push @pending_n, $n;
  #         push @pending_order, $order;
  #       }
  #       next;
  #     }
  #
  #     ### assert: abs($order) >= 2
  #
  #     foreach my $right (0, 1) {
  #       $order--;
  #       my $new_n;
  #       if ($order || $zero_node) {
  #         $new_n = $add->($n);
  #         if ($order >= 2 || ($right && $right_stretch)) {
  #           push @pending_n, $new_n;
  #           push @pending_order, ($right && $right_stretch ? -$order : $order);
  #         }
  #       }
  #     }
  #   }
  #   return $graph;
  # }



=for stopwords Ryde subtrees Steinhaus Stechert AVL ie undirected Viswanathan Iyer Udaya Kumar Reddy WTb preprint MeanDist OEIS

=head1 NAME

Graph::Maker::FibonacciTree - create Fibonacci tree graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::FibonacciTree;
 $graph = Graph::Maker->new ('fibonacci_tree', height => 4);

=head1 DESCRIPTION

C<Graph::Maker::FibonacciTree> creates C<Graph.pm> graphs of Fibonacci
trees.

Various authors give different definitions of a Fibonacci tree.  The
conception here is to start with year-by-year rabbit genealogy, which is
rows of width F(n), and optionally reduce out some vertices.  The
C<series_reduced> form below is quite common, made by a recursive definition
of left and right subtrees T(k-1) and T(k-2).  A further C<leaf_reduced> is
then whether to start T(0) empty rather than a single vertex.

=head2 Full Tree

The default tree is in the style of

=over

Hugo Steinhaus "Mathematical Snapshots", Stechert, 1938, page 27

=back

starting the tree at the first fork,

            1
          /   \          height => 4
        2       3
       / \      |
      4   5     6
     / \  |    / \
    7  8  9  10   11

The number of nodes in each row are the Fibonacci numbers 1, 2, 3, 5, etc.

A tree of height H has a left sub-tree of height H-1 but the right delays by
one level and under there is a tree height H-2.

                tree(H)
              /        \             tree of height H
        tree(H-1)       node
         /    \           |
     tree(H-2) node    tree(H-2)
       /   \    |       /    \
     ...  ...  ...    ...   ...

This is the genealogy of Fibonacci's rabbit pairs.  The root node 1 is a
pair of adult rabbits.  They remain alive as node 2 and they have a pair of
baby rabbits as node 3.  Those babies do not breed immediately but only in
the generation after at node 6.  Every right tree branch is a baby rabbit
pair which does not begin breeding until the month after.

The tree branching follows the Fibonacci word.  The Fibonacci word begins as
a single 0 and expands 0 -E<gt> 01 and 1 -E<gt> 0.  The tree begins as a
type 0 node in the root.  In each level a type 0 node has two child nodes, a
0 and a 1.  A type 1 node is a baby rabbit pair and it descends to be a type
0 adult pair at the next level.

=head2 Series Reduced

Option C<series_reduced =E<gt> 1> eliminates non-leaf delay nodes.  Those
are all the nodes with a single child, leaving all nodes with 0 or 2
children.  In the height 4 example above they are nodes 3 and 5.  The result
is

            1
          /   \          height => 4
        2       3        series_reduced => 1
       / \     / \
      4   5   6   7
     / \
    8   9

A tree order k has left sub-trees order k-1 and right sub-tree k-2, starting
from orders 0 and 1 both a single node.

             root               tree of order k
           /      \               starting order 0 or 1 = single node
    order(k-1)    order(k-2)

This is the style of Knuth volume 3 section 6.2.1.

=cut

# GP-DEFINE  F(n) = fibonacci(n);
# GP-Test  vector(5,n,my(n=n-1); 2*F(n+1)-1) == [1,1,3,5,9]

=pod

Each node has 0 or 2 children.  The number of nodes of each type in tree
height H are

                       count
                     ----------
    0 children         F(H+1)
    2 children         F(H+1)-1
    total nodes      2*F(H+1)-1

=for GP-Test  my(H=4); 2*F(H+1)-1 == 9

=head2 Series and Leaf Reduced

Options C<series_reduced =E<gt> 1, leaf_reduced =E<gt> 1> together eliminate
all the delay nodes.

            1
          /   \          height => 4
        2       3        series_reduced => 1
       / \     /         leaf_reduced => 1
      4   5   6
     /
    7

This style can be formed by left and right sub-trees of order k-1 and k-2,
with an order 0 reckoned as no tree at all and order 1 a single node.

             root               tree of order k
           /      \               starting order 0 = no tree at all
    order k-1     order k-2                order 1 = single node


In this form nodes can have 0, 1 or 2 children.  For a tree height H the
number of nodes with each, and the total nodes in the tree, are

                    count
                   -------
    0 children      F(H)
    1 children      F(H-1),   or 0 when H=0
    2 children      F(H) - 1, or 0 when H=0
    total nodes     F(H+2)-1

=cut

# GP-Test  my(H=4); F(H+2)-1 == 7
# GP-Test  vector(5,n,n--; F(n+2)-1) == [0,1,2,4,7]
# GP-Test  vector(100,n,n--; F(n) + if(n==0,0,F(n-1)) + if(n==0,0,F(n)-1)) == vector(100,n,n--; F(n+2)-1)
# GP-Test  vector(100,n,my(n=n-1); 2*F(n+1)-1 - (F(n+2)-1)) == vector(100,n,my(n=n-1); F(n-1))

=pod

The 1-child nodes are where C<leaf_reduced> has removed a leaf node from the
C<series_reduced> form.

This tree form is the maximum unbalance for an AVL tree.  In an AVL tree
each node has left and right sub-trees with height differing by at most 1.
This Fibonacci tree has every node with left and right sub-tree heights
differing by 1.

=head2 Leaf Reduced

Option C<leaf_reduced =E<gt> 1> alone eliminates from the full tree just the
delay nodes which are leaf nodes.  In the height 4 example in L</Full Tree>
above these are nodes 8 and 11.

            1
          /   \          height => 4
        2       3        leaf_reduced => 1
       / \      |
      4   5     6
     /    |    /
    7     8   9

The effect of this is merely to repeat the second last row, ie. there is a
single child under every node of the second last row.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('fibonacci_tree', key =E<gt> value, ...)>

The key/value parameters are

    height          =>  integer
    series_reduced  =>  boolean (default false)
    leaf_reduced    =>  boolean (default false)
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

C<height> is how many rows of nodes.  So C<height =E<gt> 1> is a single row,
being the root node only.

Like C<Graph::Maker::BalancedTree>, if the graph is directed (the default)
then edges are added both up and down between each parent and child.  Option
C<undirected =E<gt> 1> creates an undirected graph and for it there is a
single edge from parent to child.

=back

=head1 FORMULAS

=head2 Wiener Index - Series and Leaf Reduced

The Wiener index of the series and leaf reduced tree is calculated in

=over

K. Viswanathan Iyer and K. R. Udaya Kumar Reddy, "Wiener index of
Binomial Trees and Fibonacci Trees", Intl J Math Engg with Comp, 2009.
arxiv:0910.4432

=back

They form a recurrence from the left and right sub-trees and new root, using
also a sum of distances down just from the root.  For a tree order k (which
is also height k), those root distances total

    DTb(k) = 1/5*(k-3)*F(k+3) + 2/5*(k-2)*F(k+2) + 2
           = 0, 0, 1, 4, 11, 26, 56, 114, 223, ...      (A002940)

=cut

# GP-DEFINE  DTb(k) = 1/5*(k-3)*F(k+3) + 2/5*(k-2)*F(k+2) + 2;
# GP-Test  my(v=[0,0,1,4,11,26,56,114,223,424,789,1444,2608,4660,8253,14508]); vector(#v,k,k--; DTb(k))==v

# Iyer and Reddy preprint
#      WTb(k-1) + WTb(k-2)  + F(k+1) * DTb(k-2)     <-- same
#                           + (F(k)-1) * DTb(k-1)   \ different
#          + F(k+1) * (F(k) - 1)                    /

=pod

A recurrence for the Wiener index is then as follows.  (Not the same as the
WTb formula in their preprint.  Is there a typo there?)

    WTb(k) = WTb(k-1) + WTb(k-2) + F(k+1)*DTb(k-2) + F(k)*DTb(k-1)
             + 2*F(k+1)*F(k) - F(k+2)

    starting WTb(0) = WTb(1) = 0

=cut

# GP-DEFINE  WTb_by_recurrence(k) = {
# GP-DEFINE    if(k==0,0, k==1,0,
# GP-DEFINE       WTb(k-1) + WTb(k-2) + F(k+1)*DTb(k-2) + F(k)*DTb(k-1)
# GP-DEFINE       + 2*F(k+1)*F(k) - F(k+2) );
# GP-DEFINE  }

=pod

They suggest an iteration to evaluate upwards.  Some generating function
manipulations can also sum through to

    WTb(k) = 1/10 * ( (2*k+13) * (F(k+2) + 1)*(F(k+2) + F(k+4))
                      + F(k+2)*(10 - 29*F(k+4))  - 9*F(k+4) )

           = 0, 0, 1, 10, 50, 214, 802, 2802, 9275, ...    (A192019)

=cut

# GP-DEFINE  WTb(k) = 1/10 * ( (2*k+13) * (F(k+2) + 1)*(F(k+2) + F(k+4)) \
# GP-DEFINE                    + F(k+2)*(10 - 29*F(k+4)) - 9*F(k+4) );
# GP-Test  my(v=[0,0,1,10,50,214,802,2802,9275,29580,91668,277924,828092,2433140]); vector(#v,k,k--; WTb(k))==v
# GP-Test  vector(100,k,k--; WTb_by_recurrence(k))==vector(100,k,k--; WTb(k))

=pod

More Fibonacci identities might simplify further.  Term F(k+2)+F(k+4) is the
Lucas numbers.

There are F(k+2)-1 many vertices in the tree so a mean distance between
distinct vertices is

    MeanDist(k) = WTb(k) / binomial(F(k+2)-1, 2)

The tree diameter is 2*k-3 which is attained between the deepest vertices of
the left and right sub-trees.  A limit for MeanDist as a fraction of that
diameter is found by noticing the diameter cancels 2*k in WTb and using
F(k+n)/F(k) -E<gt> phi^n, where phi=(1+sqrt5)/2 is the Golden ratio

    MeanDist(k)           1 + phi^2    2 + phi       1
    ----------- ->  MTb = ---------  = -------  = -------
    Diameter(k)              5            5       3 - phi

                = 0.723606...   (A242671)

=cut

# GP-DEFINE  sqrt5 = quadgen(20);
# GP-Test  sqrt5^2 == 5
# GP-DEFINE  phi = (1+sqrt5)/2;
# GP-DEFINE  MeanDist_limit = (1 + phi^2)/5;
# GP-Test  MeanDist_limit == (2 + phi)/5
# GP-Test  MeanDist_limit == 1/(3-phi)
# 1/5 * (1 + phi^2) * 1.0
# 1/5 * (2 + phi) * 1.0
# 1/10 * (5 + sqrt5) * 1.0
# 1/2 + 1/2*1/sqrt5 * 1.0

=pod

=head2 Wiener Index - Series Reduced

A similar calculation for the series reduced form is, for tree order k,

    DS(k) = 1/5*(4*k-2)*F(k+1) + 1/5*(2*k-8)*F(k+2) + 2
          = 0, 0, 2, 6, 16, 36, 76, 152, 294, ...     (A178523)

    WS(k) = 1/5*( (2*k-18)* (2*F(k+1) + 1) * (2*F(k+1) + F(k+2))
                  + 78*F(k+1)^2 + 54*F(k+1) + 30*F(k+2)  )
          = 0, 0, 4, 18, 96, 374, 1380, 4696, 15336, ...    (A180567)

=cut

# GP-DEFINE  DS(k) = 1/5*(4*k-2)*F(k+1) + 1/5*(2*k-8)*F(k+2) + 2;
# GP-Test  my(v=[0,0,2,6,16,36,76,152,294,554,1024,1864,3352,5968,10538]); vector(#v,k,k--; DS(k))==v
# GP-DEFINE  WS(k) = 1/5*( (2*k-18)* (2*F(k+1) + 1) * (2*F(k+1) + F(k+2)) \
# GP-DEFINE                + 78*F(k+1)^2 + 54*F(k+1) + 30*F(k+2)  );
# GP-Test  my(v=[0, 0, 4, 18, 96, 374, 1380, 4696, 15336, 48318, 148448, 446890]); vector(#v,k,k--; WS(k))==v

=pod

With vertices 2*F(k+1)-1 and diameter 2*k-3 again (for kE<gt>=2) the limit
for mean distance between vertices as a fraction of the diameter is the same
as above.

                   WS(k)                       
   --------------------------------------  ->  MTb  same
   Diameter(k) * binomial(2*F(k+1)-1), 2)      

=cut

# GP-DEFINE  DiameterS(k) = 2*k-3;
# my(k=1000); WS(k)/DiameterS(k) / binomial(NS(k),2)*1.0

=pod

=head2 Wiener Index - Full Tree

A further similar calculation for the full tree of height k gives

    Dfull(k) = k*F(k+3) - F(k+5) + 5
             = 0, 0, 2, 8, 23, 55, 120, 246, ...

    Wfull(k) = 1/10 * ( (2*k-1)*( 5*F(k+3)^2  + 2*( 2*F(k+3) + F(k+4)) )
                        + 5*( F(k+4) - 6*F(k+3) + 18 )*F(k+4)
                        - 91*F(k+2) - 10  );
             = 0, 0, 4, 32, 174, 744, 2834, 9946, ...

=cut

# GP-DEFINE  Dfull(k) = k*F(k+3) - F(k+5) + 5;
# GP-Test  my(v=[0, 0, 2, 8, 23, 55, 120, 246, 484, 924]); vector(#v,k,k--; Dfull(k))==v
# GP-DEFINE  Wfull(k) = {
# GP-DEFINE    1/10 * ( (2*k-1)*( 5*F(k+3)^2 + 2*( 2*F(k+3) + F(k+4)) )
# GP-DEFINE             + 5*( F(k+4) - 6*F(k+3) + 18 )*F(k+4)
# GP-DEFINE             - 91*F(k+2) - 10  );
# GP-DEFINE  }
# GP-Test  my(v=[0,0,4,32,174,744,2834,9946,33088]); vector(#v,k,k--; Wfull(k))==v

=pod

With number of vertices F(k+3)-2 and diameter 2*k-2 (for kE<gt>=1) the limit
for mean distance between vertices as a fraction of the diameter is
simply 1.  (The only term in k*F^2 is the (2*k-1)*F(k+3)^2.)

                  Wfull(k)                       
   ------------------------------------  ->  1
   Diameter(k) * binomial(F(k+3)-2), 2)      

=cut

# GP-DEFINE  Nfull(k) = F(k+3)-2;
# GP-DEFINE  DiameterFull(k) = 2*k-3;
# my(k=10000); Wfull(k)/DiameterFull(k) / binomial(Nfull(k),2)*1.0

=pod

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
these graphs include

=over

L<http://oeis.org/A180567> (etc)

=back

    series_reduced=>1
      A180567   Wiener index
      A178523   distance root to all vertices
      A178522   number of vertices at depth

    series_reduced=>1,leaf_reduced=>1
      A192019   Wiener index
      A002940   distance root to all vertices
      A023610     increment of that distance
      A242671   mean distance limit between vertices
                  as fraction of tree diameter, being (1+1/sqrt(5))/2
      A192018   count nodes at distance

=cut

# k=0 N=1 vertex   W=0
# k=1 N=2 vertices W=1
# k=2 N=4 vertices path, W=3+2+1 + 2+1 + 1 = 10

=pod

=head1 SEE ALSO

L<Graph::Maker>, L<Graph::Maker::BalancedTree>

L<Math::NumSeq::FibonacciWord>

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
