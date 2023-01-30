# Copyright 2021 Kevin Ryde
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

package Graph::Maker::HanoiSwitching;
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

sub _vertex_names_func_digits {
  my ($digits, $spindles) = @_;
  return join('', reverse @$digits);
}
sub _vertex_names_func_integer {
  my ($digits, $spindles) = @_;
  my $ret = 0;
  foreach my $digit (reverse @$digits) {  # digits high to low
    $ret = $ret*$spindles + $digit;
  }
  return $ret;
}

sub init {
  my ($self, %params) = @_;
  ### HanoiSwitching init: %params

  my $discs     = delete($params{'discs'})     || 0;
  my $spindles  = delete($params{'spindles'})  || 3;
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  # this not documented yet ...
  my $vertex_names = delete($params{'vertex_names'}) || 'integer';
  my $vertex_name_func = $self->can("_vertex_names_func_$vertex_names")
    || croak "Unrecognised vertex_names: ",$vertex_names;

  my $graph = $graph_maker->(%params);

  $graph->set_graph_attribute
    (name =>
     "Hanoi Switching $discs"
     . ($spindles == 3 ? '' : " Discs, $spindles Spindles"));

  # $t[$d] is the spindle number (0 .. $spindles-1) which holds disc $d.
  # $d = 0 is the smallest disc.
  my @t = (0) x $discs;
  my $add_edge = ($graph->is_directed ? 'add_cycle' : 'add_edge');
 T: for (;;) {
    my $v = $vertex_name_func->(\@t, $spindles);
    $graph->add_vertex($vertex_name_func->(\@t, $spindles));
    ### from: "v= ".join(',',@t)

    if ($discs) {
      # smallest disc moves freely
      my @t2 = @t;
      my $from = $t[0];   # spindle holding smallest disc
      foreach my $to (0 .. $from-1) {
        $t2[0] = $to;
        my $v2 = $vertex_name_func->(\@t2, $spindles);
        $graph->$add_edge($v, $v2);
      }

      # smallest disc and consecutives on its spindle switch with next bigger
      foreach my $pos (1 .. $#t) {
        if ($t[$pos] != $from) {
          @t2 = @t;
          foreach my $i (0 .. $pos-1) { $t2[$i] = $t[$pos]; }
          $t2[$pos] = $from;
          my $v2 = $vertex_name_func->(\@t2, $spindles);
          $graph->$add_edge($v, $v2);
          last;
        }
      }
    }

    # increment t vector ...
    foreach my $pos (0 .. $#t) {
      next T if ++$t[$pos] < $spindles;
      $t[$pos] = 0;
    }
    last; # no more @t configurations
  }
  return $graph;
}

Graph::Maker->add_factory_type('hanoi_switching' => __PACKAGE__);
1;

__END__

=for stopwords Ryde eg undirected et al

=head1 NAME

Graph::Maker::HanoiSwitching - create towers of Hanoi exchanging discs graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::HanoiSwitching;
 $graph = Graph::Maker->new ('hanoi_switching', discs => 3);

=head1 DESCRIPTION

C<Graph::Maker::Hanoi> creates a C<Graph.pm> graph of configurations of
discs on spindles in a variation on the towers of Hanoi puzzle where a stack
of discs switches with the next bigger disc.

=over

Sandi Klavzar, Uros Milutinovic, "Graphs S(n,k) and a Variant of the Tower
of Hanoi Problem",

=back

    0---3--12--15       discs => 2
    | X |   | X |       spindles => 4
    1---2  13--14
    |     X     |       where each X is
    4---7   8--11       edges crossing
    | X |   | X |
    5---6---9--10

The puzzle has N discs and S spindles.  The discs on a spindle are stacked
in size order, smallest at the top.  Each graph vertex is a configuration of
discs on spindles.  Each graph edge is a legal move, which in the variation
here is

=over

=item

Stack 1..k-1 on top of one spindle switches places with disc k on top of
another spindle.  Disc k=1 is the smallest and can switch with an empty
stack (so moves freely).

=back

Klavzar and Milutinovic show that for S=3 spindles the resulting graph is
isomorphic to the plain Hanoi graph.

Moves of the smallest disc are complete-S subgraphs.  They are cross
connected at a different vertex each, which is where a N-1 discs is on one
spindle.  In the illustration above, the complete 0..3 cross connects 1-4,
2-8, 3-12.  For S=3, further connections are from 5,10,15 to copies of the
S=2 graph.

Vertices are integers 0 to S^N-1 inclusive and each digit in base S is which
spindle 0..S-1 holds the disc.  The least significant digit is the smallest
disc.  The edges are then to change the least significant digit to another
value; or the run of low digits equal to the least significant switches
values with the next higher digit (the lowest not equal to the least
significant).

         high      low
   from   2 1 0 2 2 2
   to     2 1 2 0 0 0
              \-----/

Discs=1 is always a complete-S since the single disc can move from anywhere
to anywhere.

Spindles=1 is allowed but is a trivial 1-vertex graph since all discs are on
that spindle and no moves are possible.

Spindles=2 is allowed but is a path of 2^N vertices, by alternately moving
the smallest or switching.  This is consecutive 0 to 2^N-1,

    00000    spindles => 2, in binary
    00001
    00010    alternately move smallest and switch low run 1s
    00011
    00100
    ...

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('hanoi_switching', key =E<gt> value, ...)>

The key/value parameters are

    discs     =>  integer
    spindles  =>  integer, default 3
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

L<https://hog.grinvin.org/ViewGraphInfo.action?id=21136> (etc)

=back

    spindles=3 (default)
      same as Hanoi

    spindles=4
      discs=0             1310  singleton
      discs=1               74  complete-4

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Hanoi>,
L<Graph::Maker::HanoiExchange>,
L<Graph::Maker::Complete>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2021 Kevin Ryde

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
