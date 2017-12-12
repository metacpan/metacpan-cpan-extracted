# Copyright 2017 Kevin Ryde
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


# A. M. Hinz et al, The Tower of Hanoi -- Myths and Maths, Springer 2013


package Graph::Maker::TowerOfLondon;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 10;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

# sub _vertex_names_digits {
#   my ($digits, $spindles) = @_;
#   return join('',@$digits);
# }
# sub _vertex_names_integer {
#   my ($digits, $spindles) = @_;
#   my $pow = 1;
#   my $ret = 0;
#   foreach my $i (reverse 0 .. $#$digits) {
#     $ret += $digits->[$i] * $pow;
#     $pow *= $spindles;
#   }
#   return $ret;
# }
# my %vertex_names = (integer => \&_vertex_names_integer,
#                     digits  => \&_vertex_names_digits);

sub init {
  my ($self, %params) = @_;
  my $balls     = delete($params{'balls'});
  if (! defined $balls) { $balls = 3; }
  my $spindles  = delete($params{'spindles'})  || 3;
  my $adjacency = delete($params{'adjacency'}) || 'any';
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  # this not documented yet ...
#   my $vertex_names = delete($params{'vertex_names'}) || 'integer';
# $vertex_names{$vertex_names}
#     || croak "Unrecognised vertex_names: ",$vertex_names;
  my $vertex_name_func = sub {
    my ($state) = @_;
    return join('|', map {join(',', reverse @$_)} @$state);
  };

  my $graph = $graph_maker->(%params);

  {
    my $name = "Tower of London $balls";
    if ($spindles != 3) {
      $name .= " Balls, $spindles Spindles";
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

  my @pending = [ (([]) x ($spindles-1)), [1..$balls] ];
  $graph->add_vertex($vertex_name_func->($pending[0])); # in case balls=0
  while (@pending) {
    my $from_state = pop @pending;
    my $from_v = $vertex_name_func->($from_state);
    ### $from_v

    foreach my $from_spindle (0 .. $#$from_state) {
      my $from_aref = $from_state->[$from_spindle];
      next unless @$from_aref;
      ### $from_spindle
      my $from_aref_shortened = [ @$from_aref ];
      my $ball = pop @$from_aref_shortened;

      foreach my $to_spindle (0 .. $#$from_state) {
        next if $from_spindle == $to_spindle;
        my $to_aref = $from_state->[$to_spindle];
        next if $#$to_aref >= $to_spindle;  # maximum capacity

        my $to_state = [ @$from_state ];
        $to_state->[$from_spindle] = $from_aref_shortened;
        $to_state->[$to_spindle]   = [ @$to_aref, $ball ];

        my $to_v = $vertex_name_func->($to_state);
        ### $to_spindle
        ### $to_v

        unless ($graph->has_vertex($to_v)) {
          push @pending, $to_state;
        }
        $graph->add_edge($from_v, $to_v);
      }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('tower_of_london' => __PACKAGE__);
1;

__END__

=for stopwords Ryde eg subgraphs undirected

=head1 NAME

Graph::Maker::TowerOfLondon - create tower of London puzzle graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::TowerOfLondon;
 $graph = Graph::Maker->new ('tower_of_london', balls => 3);

=head1 DESCRIPTION

C<Graph::Maker::TowerOfLondon> creates a C<Graph.pm> graph of configurations
occurring in the tower of London puzzle.

The tower of London puzzle has 3 spindles which can hold at most 1,2,3 balls
respectively.  3 balls are in some arrangement on the spindles.  The aim is
to go from one specified configuration to another.

Each graph vertex is a configuration of balls on spindles.  Each edge is a
legal move from one configuration to another.  A legal move is to take the
top ball from any spindle and move it to the top of another, provided it
fits in the capacity of the destination (1,2,3 for spindle numbers 1,2,3
respectively).

=cut

# first 0,1
# second 0,1,2
# third 0,1,2,3

=pod

=head2 Spindles

Option C<spindles =E<gt> S> specifies how many spindles are used for the
puzzle.  The default is 3 as described above.  For S spindles and N balls
the vertices are numbered ...

Spindles=1 is allowed but is a trivial 1-vertex graph since all balls are on
that spindle and no moves are possible.

Spindles=2 is allowed but is 2^N vertices in pairs since only the smallest
ball can ever move.

Balls=1 is always a complete-S graph since the single ball can move from
anywhere to anywhere.

Balls E<gt>= 2 has complete-S sub-graphs which are one of the balls moving
around anywhere.  Connections between those subgraphs ...

=cut

# =head2 Cyclic
# 
# Option C<adjacency =E<gt> "cyclic"> treats the spindles as a cycle where
# balls can only move forward or backward to adjacent spindles in the cycle.
# In the vertex digit representation the cycle is around digits 0 to S-1, so
# digit changes are +/-1 mod S.
# 
# For spindlesE<lt>=3 cyclic is the same as adjacency "any".  For
# spindlesE<gt>=4 some moves between spindles are disallowed when cyclic, so
# is an edge subset of adjacency "any".
# 
# (This option is for cyclic with moves in either direction.  Another
# possibility is cyclic with moves only in one direction around the cycle, as
# considered by Scorer, Grundy and Smith.  There's nothing yet here for a
# directed graph of this kind.)
# 
# =head2 Linear
# 
# Option C<adjacency =E<gt> "linear"> treats the spindles as a row and balls
# can only move forward or backward between consecutive spindles in the row.
# 
# In the vertex digit representation the row is digits 0 to S-1, so digit
# changes +/-1 in the middle or +1 or -1 at the ends.
# 
# The puzzle is to move all balls from the first spindle to the last, which
# means a path from vertex 0 to S^N-1.
# 
# For spindlesE<lt>=2 linear is the same as "any".  For spindlesE<gt>=3 some
# moves between spindles are disallowed when linear, so an edge subset of
# cyclic, which in turn an edge subset of any.
# 
#             edges
#     ---------------------
#     any = cyclic = linear       for spindles <= 2
#     any = cyclic > linear       for spindles = 3
#     any > cyclic > linear       for spindles >= 4
# 
# =head2 Star
# 
# Option C<adjacency =E<gt> "star"> has one centre spindle and balls can move
# only between that centre and another spindle (no moves among the other
# spindles).
# 
# 
# For spindlesE<lt>=2 star is the same as "any".  For spindles=3 star is
# equivalent to linear above but with digit change 0E<lt>-E<gt>1 (different
# centre).  For spindlesE<gt>=4 star is an edge subset of adjacency "any".

=pod

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('tower_of_london', key =E<gt> value, ...)>

The key/value parameters are

    balls     =>  integer
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
