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

package Graph::Maker::Firecracker;
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

sub init {
  my ($self, %params) = @_;

  my $N = delete($params{'N'});
  my $K = delete($params{'K'});
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);
  $graph->set_graph_attribute (name => "Firecraker $N,$K");

  if ($K >= 1) {
    my $directed = $graph->is_directed;
    my $connect;
    my $v = 1;

    foreach (1 .. $N) {
      if ($K >= 2) {
        my $centre = $v++;
        my $to;
        foreach (2 .. $K) {
          $to = $v++;
          $graph->add_edge($centre, $to);
          if ($directed) { $graph->add_edge($to, $centre); }
        }
        if (defined $connect) {
          $graph->add_edge($connect, $to);
          if ($directed) { $graph->add_edge($to, $connect); }
        }
      }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('firecracker' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::Firecracker - create chain of star graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Firecracker;
 $graph = Graph::Maker->new ('firecracker', N_list => [3,1,4]);

=head1 DESCRIPTION

C<Graph::Maker::Firecracker> creates C<Graph.pm> firecracker graphs.
A firecracker graph is a set of N stars each of K vertices which are
connected in a line at a leaf of each.  For example

      *   *       *   *       *   *        
       \ /         \ /         \ /         N => 3   many stars
    *---*---*   *---*---*   *---*---*      K => 5   vertices each star
        |           |           |      
        *-----------*-----------*

Must have K >= 2 so that each star has a leaf node.  All the stars have the
same K vertices, so total vertices N*K.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('firecracker', key =E<gt> value, ...)>

The key/value parameters are

    N => integer
    K => integer
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added in both
directions.  Option C<undirected =E<gt> 1> creates an undirected graph and
for it there is a single edge each.

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Star>

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
