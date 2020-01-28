# Copyright 2017, 2018, 2019, 2020 Kevin Ryde
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

package Graph::Maker::NoughtsAndCrosses;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 15;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments '###';


sub _make_graph {
  my ($params) = @_;
  if (my $graph_maker = delete($params->{'graph_maker'})) {
    return $graph_maker->(%$params);
  }
  require Graph;
  return Graph->new(%$params);
}

sub init {
  my ($self, %params) = @_;

  my $N = delete $params{'N'};
  if (! defined $N) { $N = 3; }
  my $rotate  = delete $params{'rotate'};
  my $reflect = delete $params{'reflect'};
  my $players = delete $params{'players'};
  if (! defined $players) { $players = 2; }

  ### $N
  ### $players
  ### $rotate
  ### $reflect

  my $graph = _make_graph(\%params);
  {
    my $name = "Noughts and Crosses ${N}x$N";
    if ($players != 2) {
      $name .= ", $players Player" . ($players==1 ? '' : 's');
    }
    if ($rotate || $reflect) { $name .= ' up to '; }
    $name .= join(' and ',
                  ($rotate  ? ('Rotation')   : ()),
                  ($reflect ? ('Reflection') : ()));
    $graph->set_graph_attribute (name => $name);
  }

  # FIXME: should N=0 board be empty graph or single vertex?
  if ($N >= 0) {
    # $players = min($players, $N*$N);

    my $join = ($players < 10 ? '' : ',');
    my $hi = $N-1;
    my $state_to_str = sub {
      my ($state) = @_;
      return join($join, @$state);

      # return $state;
      # for (my $pos = $N*$hi; $pos > 0; $pos -= $N) {
      #   substr($state,$pos,0, '-');
      # }
      # return $state;
    };

    my $initial_state = [ ('0') x ($N*$N) ];
    my $initial_state_str = $state_to_str->($initial_state);
    $graph->add_vertex($initial_state_str);

    if ($players >= 1) {
      ### $N
      ### $hi
      ### $players

      my $xy_to_n = sub {
        my ($x,$y) = @_;
        return $x + $N*$y;
      };

      my @lines;
      {
        @lines = ([ map {$xy_to_n->($_,$_)} 0..$hi ],      # leading diag
                  [ map {$xy_to_n->($hi-$_,$_)} 0..$hi ]); # opposite diag
        foreach my $y (0 .. $hi) {
          push @lines, [ map {$xy_to_n->($_,$y)} 0..$hi ];  # row
        }
        foreach my $x (0 .. $hi) {
          push @lines, [ map {$xy_to_n->($x,$_)} 0..$hi ];  # column
        }
      }
      my $state_is_winning = sub {
        my ($state, $player) = @_;
        foreach my $line (@lines) {
          if ($N == grep {$state->[$_] == $player} @$line) {
            return 1;
          }
        }
        return 0;
      };

      # 2 3  -> 0 2
      # 0 1     1 3
      my $rotate_state = sub {
        my ($state) = @_;
        my @new_state;
        foreach my $y (0 .. $hi) {
          foreach my $x (0 .. $hi) {
            my $rx = $hi-$y;
            my $ry = $x;
            # map: "$x,$y -> $rx,$ry"
            push @new_state, $state->[$xy_to_n->($rx,$ry)];
          }
        }
        return \@new_state;
      };

      # r: $rotate_state->('0123')

      my $reflect_state = sub {
        my ($state) = @_;
        my @new_state;
        foreach my $y (0 .. $hi) {
          foreach my $x (0 .. $hi) {
            my $rx = $hi - $x;
            push @new_state, $state->[$xy_to_n->($rx,$y)];
          }
        }
        return \@new_state;
      };

      my $all_symmetries = sub {
        my ($state) = @_;
        my @ret = ($state);
        if ($rotate) {
          foreach (2 .. 4) {
            push @ret, $rotate_state->($ret[-1]);
          }
          # rotates: @ret
        }
        if ($reflect) {
          @ret = map {$_, $reflect_state->($_)} @ret;
        }
        return @ret;
      };

      my %canonical;
      my $state_to_canonical = sub {
        my ($state) = @_;
        if ($rotate || $reflect) {
          if (defined(my $new_state = $canonical{$state_to_str->($state)})) {
            return $new_state;
          }
          foreach my $sym_state ($all_symmetries->($state)) {
            $canonical{$state_to_str->($sym_state)} = $state;
          }
        }
        return $state;
      };

      # Recursion goes down to the depth of the graph, which means up to N^2.
      # Could do this in an array instead of on the stack, but expect only
      # graphs of smallish N are practical anyway,
      my $recurse;
      $recurse = sub {
        my ($state, $state_str, $player) = @_;
        $player++;
        if ($player > $players) { $player = 1; }
        ### recurse: "$state_str  player $player"

        my %this_seen;
        foreach my $pos (0 .. $#$state) {
          if ($state->[$pos]) {
            ### already filled: $pos
            next;
          }
          ### $pos
          my $new_state = [@$state];
          $new_state->[$pos] = $player;
          $new_state = $state_to_canonical->($new_state);
          my $new_state_str = $state_to_str->($new_state);

          my $stop_here = $state_is_winning->($new_state, $player)
            || $graph->has_vertex($new_state_str);

          # only one edge if symmetry makes same destinations
          unless ($this_seen{$new_state_str}++) {
            $graph->add_edge($state_str, $new_state_str);
          }

          unless ($stop_here) {
            #### to: $new_state
            $recurse->($new_state, $new_state_str, $player);
          }
        }
      };
      $recurse->($initial_state, $initial_state_str, 0);
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('noughts_and_crosses' => __PACKAGE__);
1;

__END__

=for stopwords Ryde NxN subgraph tesseract predecessorless undirected OEIS

=head1 NAME

Graph::Maker::NoughtsAndCrosses - create noughts and crosses graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::NoughtsAndCrosses;
 $graph = Graph::Maker->new ('noughts_and_crosses', N => 3);

=head1 DESCRIPTION

C<Graph::Maker::NoughtsAndCrosses> creates C<Graph.pm> graphs of noughts and
crosses games.  Each vertex is the state of the board, starting from an
empty board.  Each edge is a move by a player, adding a nought or cross and
going to a new board state.  The game stops when one player has a winning
line or the board is full (which might be win or draw).

The format of vertex names is unspecified.  Currently they're a string of
board contents, 0 for empty square, 1 or 2 for player's piece.  But don't
rely on that.

=head2 Board Size

Option C<N =E<gt> $integer> is the board size NxN, for NE<gt>=1.

The number of vertices quickly becomes very large, so 3x3 is about the
biggest which it's practical to calculate.  Some of the options below reduce
combinations enough to allow 4x4.

N=1 is a board of 1 cell which is trivially won by the first player, so a 2
vertex graph.  N=2 is also always won by the first player, but with more
structure.

=head2 Players

Option C<players =E<gt> $integer> is the number of players in the game.

0 players means no moves so a single vertex for the empty board.

1 player means placing pieces until reaching a filled line.  On a 2x2 board
any 2 places make a line so the states are just 4 positions with up to 2
filled.  This is an induced subgraph of the tesseract
(L<Graph::Maker::Hypercube> with N=4).  A corner of the tesseract is the
empty board then filling is vertices distance <= 2 from there.
Other size boards are also induced sub-graphs of an N^2 dimensional
hypercube, but the rule for which vertices to include is not as simple.

=cut

# GP-Test  my(n=2); n^2-n == 2
# GP-Test  my(n=3); n^2-n == 6

=pod

1 player in general has depth from the empty board of at most N^2-N pieces
placed, since any more placed is less than N holes so not enough to prevent
a line in all rows.  On a 2x2 that's still not enough as 2 pieces can be a
column or diagonal.  On a 3x3 the only 6 piece board not yet winning is, up
to rotation or reflection,

    .  X  X
    X  .  X      1-player diagonal of unfilled squares
    X  X  .

From this there are 3 ways to reach a 7-piece win, or 2 ways up to rotation
and reflection.  These are the only 7-piece configurations which arise in
play.

    X  X  X        .  X  X
    X  .  X        X  X  X      1-player 7-piece wins
    X  X  .        X  X  .

If players > N+1 then there are not enough cells for anyone to win.  If
players > N^2 then there are more players than cells and only the first N^2
have a turn.  In that case the boards at depth d become all arrangements of
d different pieces in N^2 cells.

=cut

# P players in NxN board
# player 1 win needs N cells, other players (P-1)*(N-1) in between
# N + (P-1)*(N-1) <= N^2
# (P-1)*(N-1) <=  N^2 - N
# P-1 <= N*(N-1) / (N-1) so P<=N+1 is winnable
# GP-Test  my(P=3,N=2); N + (P-1)*(N-1) == 4

=pod

=head2 Rotation and Reflection

Options C<rotate =E<gt> $bool> and C<reflect =E<gt> $bool> treat board
states as equivalent when they are the same when rotated 90, 180 or 270
degrees, or mirror image reflection, respectively.  Rotate and reflect
together are all combinations of 0, 90, 180, 270 rotation and reflect or
not.

=cut

# The format of vertex names used under rotation and reflection is
# unspecified.  Currently the first one seen among equivalents during the
# graph construction is used.  But don't rely on that.

=pod

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('noughts_and_crosses', key =E<gt> value, ...)>

The key/value parameters are

    N        => integer, default 3, board size NxN
    players  => integer >= 1
    rotate   => boolean, default false, rotated boards equivalent
    reflect  => boolean, default false, mirror image equivalent
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are directed from old
board state to new board state.  The one predecessorless vertex is the empty
board.  Option C<undirected =E<gt> 1> creates an undirected graph.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

=item N=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=27017>

=item N=2, rotate, L<https://hog.grinvin.org/ViewGraphInfo.action?id=27020>

=item N=2, rotate, reflect L<https://hog.grinvin.org/ViewGraphInfo.action?id=945>

=item N=2, 1 player, L<https://hog.grinvin.org/ViewGraphInfo.action?id=27032>

=item N=2, 1 player, reflect, L<https://hog.grinvin.org/ViewGraphInfo.action?id=856>

=item N=2, 1 player, rotate, L<https://hog.grinvin.org/ViewGraphInfo.action?id=500>  (claw)>

=item N=2, 3 players, rotate, L<https://hog.grinvin.org/ViewGraphInfo.action?id=27025>

=item N=2, 3 players, rotate, reflect, L<https://hog.grinvin.org/ViewGraphInfo.action?id=27048>

=item N=2, 4 players, rotate, L<https://hog.grinvin.org/ViewGraphInfo.action?id=27034>

=item N=2, 4 players, rotate, reflect, L<https://hog.grinvin.org/ViewGraphInfo.action?id=27050>

=item N=3, 1 player, rotate, reflect L<https://hog.grinvin.org/ViewGraphInfo.action?id=27015>

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
these graphs include

=over

L<http://oeis.org/A008907> (etc)

=back

    3x3 with 2 players (the default)
      A061526  num NxN complete games
                being num paths from root to some successorless vertex
      A061527  num NxN games won by player 1
      A061528  num NxN games won by player 2
      A061529  num NxN games drawn
      A061221  num winning game states, after n moves
                 being num paths from root to successorless vertex,
                 excluding draws at depth 9

    3x3 with 2 players, up to rotate and reflect
      A008907    num board states after n moves
      A048245    num winning board states after n moves
      A085698    num vertices for N^2 players
      A087074    num vertices at depths for N^2 players

=head1 SEE ALSO

L<Graph::Maker>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker/index.html>

=head1 LICENSE

Copyright 2017, 2018, 2019, 2020 Kevin Ryde

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
