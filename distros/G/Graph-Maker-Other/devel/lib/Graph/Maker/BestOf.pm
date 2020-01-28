# Copyright 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde
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

package Graph::Maker::BestOf;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 15;
@ISA = ('Graph::Maker');


sub _default_graph_maker {
  require Graph;
  return Graph->new(@_);
}
sub _make_graph {
  my ($params) = @_;
  my $graph_maker = delete($params->{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%$params);
}

sub _vertex_name_scores {
  my ($a,$b) = @_;
  return "$a,$b";
}

sub init {
  my ($self, %params) = @_;

  my $N = delete($params{'N'}) || 0;
  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Best-Of $N");

  # this not documented yet ...
  my $vertex_names = delete($params{'vertex_names'}) || 'integer';
  my $score_to_vertex_name;
  if ($vertex_names eq 'integer') {
    my @s;
    my $upto = 1;
    $score_to_vertex_name = sub {
      my ($a,$b) = @_;
      return ($s[$a][$b] ||= $upto++);
    };
  } elsif ($vertex_names eq 'scores') {
    $score_to_vertex_name = \&_vertex_name_scores;
  } else {
    croak "Unrecognised vertex_names: ",$vertex_names;
  }

  my $v = $score_to_vertex_name->(0,0);
  $graph->add_vertex($v);

  if ($N > 0) {
    my $directed = $graph->is_directed;
    my $half = int($N/2);

    my @pending = ([0,0, $v]);
    while (@pending) {
      my ($a,$b, $v) = @{shift @pending};

      foreach my $add (0,1) {
        my $a2 = $a + 1-$add;
        my $b2 = $b + $add;
        my $v2 = $score_to_vertex_name->($a2,$b2);

        $graph->add_edge($v, $v2);
        # if ($directed) { $graph->add_edge($v2, $v); }

        if ($a2+$b2 < $N && $a2 <= $half && $b2 <= $half) {
          push @pending, [$a2,$b2, $v2];
        }
      }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('best_of' => __PACKAGE__);
1;

__END__






    # foreach my $remaining (reverse 0 .. $N-2) {
    #   my @new_v;
    #   my @new_score;
    #   while (@v) {
    #     my $parent = shift @v;
    #     my $score  = shift @score;
    #     foreach my $win (0, 1) {
    #       my $child = ++$upto;
    #       $graph->add_edge($parent, $child);
    #       if ($directed) { $graph->add_edge($child, $parent); }
    # 
    #       $score += $win;
    #       unless ($score > $half
    #               || $score+$remaining < $half) {
    #         push @new_v, $child;
    #         push @new_score, $score;
    #       }
    #     }
    #   }
    #   @v = @new_v;
    #   @score = @new_score;
    # }


=for stopwords Ryde

=head1 NAME

Graph::Maker::BestOf - create BestOf contest graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::BestOf;
 $graph = Graph::Maker->new ('best_of', N => 7);

=head1 DESCRIPTION

C<Graph::Maker::BestOf> creates C<Graph.pm> graphs of best-of contests.

Two players play best-of N games.  Each vertex represents a score A-B of how
many games won by each.  An edge goes from an A-B to (A+1)-B and A-(B+1)
representing player A or B winning another game.  The contest stops at N
games or when one player has an insurmountable lead.

For example best-of 3,

        1        N => 3
       / \
      2   3
     / \ / \
    4   5   6
       / \
      7   8

Vertices 4 and 6 are scores 2-0 and 0-2 where the contest has been decided
and there is no need for a 3rd game.  Vertices 7 and 8 and 2-1 or 1-2
results, having played all 3 games.

If N is even the contest can end in a draw.  For example best-of 4

        1        N => 4
       / \
      2   3
     / \ / \
    4   5   6
   / \ / \ / \
  7   8   9  10
     / \ / \
   11  12   13

Vertices 7 and 10 are 3-0 and 0-3 with no need for a 4th game.  Vertices 11
and 13 are 3-1 and 1-3 results or vertex 12 is a 2-2 draw.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('best_of', key =E<gt> value, ...)>

The key/value parameters are

    N  =>  integer, number of games
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both up and down
between each parent and child.  Option C<undirected =E<gt> 1> creates an
undirected graph and for it there is a single edge from parent to child.

=back

=head1 SEE ALSO

L<Graph::Maker>, L<Graph::Maker::BalancedTree>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker/index.html>

=head1 LICENSE

Copyright 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
