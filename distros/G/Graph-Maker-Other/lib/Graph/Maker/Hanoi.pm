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

package Graph::Maker::Hanoi;
use 5.004;
use strict;
use Carp 'croak';
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

sub _vertex_names_digits {
  my ($digits, $spindles) = @_;
  return join('',@$digits);
}
sub _vertex_names_integer {
  my ($digits, $spindles) = @_;
  my $pow = 1;
  my $ret = 0;
  foreach my $i (reverse 0 .. $#$digits) {
    $ret += $digits->[$i] * $pow;
    $pow *= $spindles;
  }
  return $ret;
}
my %vertex_names = (integer => \&_vertex_names_integer,
                    digits  => \&_vertex_names_digits);

sub init {
  my ($self, %params) = @_;
  my $discs     = delete($params{'discs'})     || 0;
  my $spindles  = delete($params{'spindles'})  || 3;
  my $adjacency = delete($params{'adjacency'}) || 'any';
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  # this not documented yet ...
  my $vertex_names = delete($params{'vertex_names'}) || 'integer';
  my $vertex_name_func = $vertex_names{$vertex_names}
    || croak "Unrecognised vertex_names: ",$vertex_names;

  my $graph = $graph_maker->(%params);

  {
    my $name = "Hanoi $discs";
    if ($spindles != 3) {
      $name .= " Discs, $spindles Spindles";
    }
    if ($adjacency ne 'any') {
      $name .= ", \u$adjacency";
    }
    $graph->set_graph_attribute (name => $name);
  }

  my $offset_limit;
  if ($adjacency eq 'any' || $adjacency eq 'star') {
    $offset_limit = $spindles - 1;
  } elsif ($adjacency eq 'cyclic' || $adjacency eq 'linear') {
    $offset_limit = 1;
  } else {
    croak "Unrecognised adjacency: ",$adjacency;
  }
  my $directed = $graph->is_directed;
  ### $directed
  ### $offset_limit

  my @t = (0) x $discs;
  $graph->add_vertex($vertex_name_func->(\@t, $spindles)); # in case discs=0

 T: for (;;) {
    my $v = $vertex_name_func->(\@t, $spindles);

    my $seen_count = 0;
    my @seen;
    foreach my $pos (reverse 0 .. $#t) {
      my $from_digit = $t[$pos];
      next if $seen[$from_digit];
      $seen[$from_digit] = 1;
      next if $from_digit && $adjacency eq 'star';

      foreach my $offset (1 .. $offset_limit) {
        my $to_digit = $from_digit + $offset;
        if ($adjacency eq 'cyclic') {
          $to_digit %= $spindles;
        } else {
          last if $to_digit >= $spindles;
        }
        next if $seen[$to_digit];  # smaller disc on other spindle

        my @t2 = @t;
        $t2[$pos] = $to_digit;
        my $v2 = $vertex_name_func->(\@t2, $spindles);
        $graph->add_edge($v, $v2);
        if ($directed) { $graph->add_edge($v2, $v); }
        ### edge: "pos=$pos @t to @t2"
      }
    }

    # increment t ...
    foreach my $pos (reverse 0 .. $#t) {
      next T if ++$t[$pos] < $spindles;
      $t[$pos] = 0;
    }
    last; # no more @t configurations
  }
  return $graph;





  # # smallest disc $t2[-1] moves to either other spindle
  # foreach (1, 2) {
  #   $t2[-1]++;
  #   $t2[-1] %= 3;
  #   if ($directed || $t2[-1] > $t[-1]) {
  #     my $v2 = $vertex_name_func->(\@t2, $spindles);
  #     ### smallest disc: "$v to $v2"
  #     $graph->add_edge($v, $v2);
  #   }
  # }
  #
  # # on the spindles without the smallest disc, can move the smaller of
  # # their two top discs
  # for (my $pos = $#t-1; $pos >= 0; $pos--) {
  #   if ($t[$pos] != $t[-1]) {
  #     @t2 = @t;
  #     $t2[$pos]++;
  #     $t2[$pos] %= 3;
  #     if ($t2[$pos] == $t[-1]) {
  #       $t2[$pos]++;
  #       $t2[$pos] %= 3;
  #     }
  #     if ($directed || $t2[$pos] > $t[$pos]) {
  #       my $v2 = $vertex_name_func->(\@t2, $spindles);
  #       ### second disc: "$v to $v2"
  #       $graph->add_edge($v, $v2);
  #     }
  #     last;
  #   }
  # }
  #

  # # done in integers
  # if (0) {
  #   my $v_max = 3**$discs - 1;
  #   my $vpad_max = 3**($discs-1) - 1;
  #   ### $discs
  #   ### $v_max
  #   ### $vpad_max
  # 
  #   foreach my $v (0 .. $v_max) {
  #     my $low = $v % 3;
  #     ### $v
  # 
  #     foreach my $inc (1, 2) {
  #       ### $low
  #       ### $inc
  #       my $other = ($low + $inc) % 3;
  #       {
  #         my $v2 = $v - $low + $other;
  #         if ($directed || $v2 > $v) {
  #           ### smallest disc: "$v to $v2"
  #           $graph->add_edge($v, $v2);
  #         }
  #       }
  # 
  #       ### $low
  #       ### $other
  #       my $pad = ($low - $inc) % 3;
  #       my $mod = 3;
  #       my $rem = $low;
  #       foreach (1 .. $discs) {
  #         $mod *= 3;
  #         $rem = 3*$rem + $low;
  #         my $got = $v % $mod;
  #         ### $mod
  #         ### $rem
  #         ### $got
  #         if ($got != $rem) {
  #           my $v2 = $v - $got + ((2*$got - $rem) % $mod);
  #           if ($directed || $v2 > $v) {
  #             ### second smallest: "$v to $v2"
  #             $graph->add_edge($v, $v2);
  #           }
  #           last;
  #         }
  #       }
  # 
  #       # my $pad = ($low - $inc) % 3;
  #       # ### $other
  #       # ### $pad
  #       #
  #       # my $vpad = $v;
  #       # for (;;) {
  #       #   ### at: "vpad=$vpad  v2=$v2"
  #       #   last if $vpad >= $vpad_max || $v2 >= $vpad_max;
  #       #   $vpad = 3*$vpad + $pad;
  #       #   $v2   = 3*$v2 + $pad;
  #       #   if ($directed || $v2 > $vpad) {
  #       #     ### second smallest: "$vpad to $v2"
  #       #   }
  #       #     $graph->add_edge($vpad, $v2);
  #       # }
  #     }
  #   }
  # }
  # 
  # return $graph;
}

  Graph::Maker->add_factory_type('hanoi' => __PACKAGE__);
1;

__END__

=for stopwords Ryde Hamiltonian eg subgraphs Reve Dudeney Stockmeyer undirected

=head1 NAME

Graph::Maker::Hanoi - create towers of Hanoi puzzle graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Hanoi;
 $graph = Graph::Maker->new ('hanoi', discs => 3);

=head1 DESCRIPTION

C<Graph::Maker::Hanoi> creates a C<Graph.pm> graph of configurations
occurring in the towers of Hanoi puzzle.  This is equivalent to points of the
Sierpinski triangle and the odd numbers in Pascal's triangle.

      0  discs=>0         0                     0
                         / \  discs=>2         / \    discs=>3
                        1---2                 1---2
      0  discs=>1      /     \               /     \
     / \              7       5             7       5
    1---2            / \     / \           / \     / \
                    8---6---3---4         8---6---3---4
                                         /             \
                                       17              22
                                       / \             / \
                                     15--16          23--21
                                     /     \         /     \
                                   12      10      20      24
                                   / \     / \     / \     / \
                                 13--14--11---9--18--19--25--26

The Hanoi puzzle has N discs and 3 spindles.  The discs on a spindle are in
size order, smallest at the top.  Each graph vertex is a configuration of
discs on spindles.  Each edge is a legal move from one configuration to
another.

There are either two or three legal moves.  The smallest disc can always
move to either of the other two spindles, and if those two other spindles
are not empty then the smaller disc of them can move to the other.

Vertex names are integers 0 to 3^N-1.  Each ternary digit is a disc and its
value 0,1,2 is which spindle holds that disc.  The least significant digit
is the smallest disc.  The legal moves are then to change the least
significant digit to either of its two other values.  Or skip the low run of
the least significant digit and at the first different digit (if there is
one) change it to the third value (not itself and not the least
significant).

    ........ L  -> L+1,L+2 mod 3
    ...M L L L  -> M+1 or M+2 mod 3, whichever is not L

The case of no digit M different from L is 00..00, 11..11 and 22..22 which
are all discs on a single spindle.  For C<discs=E<gt>3> above these are
vertices 0, 13 and 26.  These are degree 2 and other vertices are degree 3.
The puzzle is to traverse from one such all-discs corner to another.
There's many ways to do that but the shortest is 2^N-1 moves along the side
shown.

=for GP-Test  9+3+1 == 13

=for GP-Test  2*9+2*3+2 == 26

The Hanoi graph is Hamiltonian (has a cycle visiting every vertex exactly
once) by traversing each third in the style of the Sierpinski arrowhead
(eg. L<Math::PlanePath::SierpinskiArrowheadCentres>).  In C<discs=E<gt>3>
above the Hamiltonian cycle is an arrowhead traversal 4 to 8, then likewise
17 to 9, and 18 to 22.

=head2 Spindles

Option C<spindles =E<gt> S> specifies how many spindles are used for the
puzzle.  The default is 3 as described above.  For S spindles and N discs
the vertices are numbered 0 to S^N-1 inclusive and each digit in base S is
which spindle holds the disc.  An edge is a change of digit at a position p
provided that neither old nor new digit appears in any of the positions
below p (as that would mean a smaller disc on the source or destination
spindle).

Discs=1 is always a complete-S since the single disc can move from anywhere
to anywhere.

Discs E<gt>= 2 has complete-S sub-graphs which are the small disc moving
around on some configuration of the bigger discs.  Connections between those
subgraphs are moves of the bigger discs, where permitted.

The puzzle is again to move all discs from one spindle to another.  Spindles
E<gt>= 4 can be done in fewer moves than spindles=3 by taking advantage of
the extra places, but the problem of a shortest path is more difficult.  In
spindles=3 the biggest disc can only move by putting all smaller discs on
the other spindle, but for E<gt>=4 there are many ways to distribute the
smaller discs on the other spindles.

Spindles=1 is allowed but is a trivial 1-vertex graph since all discs are on
that spindle and no moves are possible.

Spindles=2 is allowed but is 2^N vertices of disconnected pairs since only
the smallest disc can ever move.

Spindles 3,4,5 appears as "The Reve's Puzzle" in

=over

"The Canterbury Puzzles and Other Curious Problems", Henry Ernest Dudeney,
1907

=back

Dudeney gives minimum move solutions for spindles=4 when discs are
triangular numbers 1,3,6,10,etc, and for spindles=5 when discs are
triangular pyramid numbers 1,4,10,20,etc.

=head2 Cyclic

Option C<adjacency =E<gt> "cyclic"> treats the spindles as a cycle where
discs can only move forward or backward to adjacent spindles in the cycle.
In the vertex digit representation the cycle is around digits 0 to S-1, so
digit changes are +/-1 mod S.

For spindlesE<lt>=3 cyclic is the same as adjacency "any".  For
spindlesE<gt>=4 some moves between spindles are disallowed when cyclic, so
is an edge subset of adjacency "any".

(This option is for cyclic with moves in either direction.  Another
possibility is cyclic with moves only in one direction around the cycle, as
considered by Scorer, Grundy and Smith.  There's nothing yet here for a
directed graph of this kind.)

=head2 Linear

Option C<adjacency =E<gt> "linear"> treats the spindles as a row and discs
can only move forward or backward between consecutive spindles in the row.
This is a form given for 4 spindles in

=over

Paul K. Stockmeyer, "Variations on the Four-Post Tower of Hanoi Puzzle",
L<http://www.cs.wm.edu/~pkstoc/boca.ps>

=back

In the vertex digit representation the row is digits 0 to S-1, so digit
changes +/-1 in the middle or +1 or -1 at the ends.

The puzzle is to move all discs from the first spindle to the last, which
means a path from vertex 0 to S^N-1.

For spindlesE<lt>=2 linear is the same as "any".  For spindlesE<gt>=3 some
moves between spindles are disallowed when linear, so an edge subset of
cyclic, which in turn an edge subset of any.

            edges
    ---------------------
    any = cyclic = linear       for spindles <= 2
    any = cyclic > linear       for spindles = 3
    any > cyclic > linear       for spindles >= 4

=head2 Star

Option C<adjacency =E<gt> "star"> has one centre spindle and discs can move
only between that centre and another spindle (no moves among the other
spindles).  This is a form given for 4 spindles in

=over

Paul K. Stockmeyer, "Variations on the Four-Post Tower of Hanoi Puzzle",
L<http://www.cs.wm.edu/~pkstoc/boca.ps>

=back

In the vertex digit representation digit 0 is the centre.

For spindlesE<lt>=2 star is the same as "any".  For spindles=3 star is
equivalent to linear above but with digit change 0E<lt>-E<gt>1 (different
centre).  For spindlesE<gt>=4 star is an edge subset of adjacency "any".

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('hanoi', key =E<gt> value, ...)>

The key/value parameters are

    discs     =>  integer
    spindles  =>  integer, default 3
    adjacency =>  string, default "any"
    graph_maker => subr(key=>value) constructor, default Graph->new

C<adjacency> can be

    "any"        any moves between spindles permitted
    "cyclic"     moves only between spindles in a cycle
    "linear"     moves only between spindles in a row
    "star"       moves only to or from centre spindle

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both forward and
backward between vertices.  Option C<undirected =E<gt> 1> creates an
undirected graph and for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

=item discs=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=21136>

=item discs=3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=22740>

=item discs=2, spindles=4, L<https://hog.grinvin.org/ViewGraphInfo.action?id=22742>

=item discs=2, spindles=4, cyclic, L<https://hog.grinvin.org/ViewGraphInfo.action?id=25141>

=item discs=2, spindles=4, linear, L<https://hog.grinvin.org/ViewGraphInfo.action?id=25143>

=item discs=2, spindles=4, star, L<https://hog.grinvin.org/ViewGraphInfo.action?id=21152>

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Complete>,
L<Graph::Maker::Cycle>,
L<Graph::Maker::Linear>

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
