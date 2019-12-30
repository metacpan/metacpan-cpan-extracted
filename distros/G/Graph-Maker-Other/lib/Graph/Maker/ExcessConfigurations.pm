# Copyright 2018, 2019 Kevin Ryde
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


package Graph::Maker::ExcessConfigurations;
use 5.004;
use strict;
use Carp 'croak';
use List::Util 'sum';
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 14;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  return Graph->new(@_);
}
sub _make_graph {
  my ($params) = @_;
  my $graph_maker = delete($params->{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%$params);
}

sub _step {
  my ($conf) = @_;
  ### _step(): join(',',@$conf)
  my @ret;
  {
    my @new_conf = @$conf;
    $new_conf[0]++;    # new r=1
    push @ret, \@new_conf;
    ### incr bicyclic: join(',',@new_conf)
  }
  foreach my $i (0 .. $#$conf) {
    if ($conf->[$i]) {
      {
        my @new_conf = @$conf;
        $new_conf[$i]--;    # raise r to r+1
        $new_conf[$i+1]++;
        push @ret, \@new_conf;
        ### raise: "i=$i to ".join(',',@new_conf)
      }
      foreach my $j ($i .. $#$conf) {
        if ($conf->[$j] > ($i==$j)) {
          my @new_conf = @$conf;
          $new_conf[$i]--;
          $new_conf[$j]--;
          my $t = $i+$j+2;
          while ($#new_conf < $t) { push @new_conf, 0; }
          $new_conf[$t]++;
          push @ret, \@new_conf;
          ### join: "i=$i j=$j to ".join(',',@new_conf)
        }
      }
    }
  }
  return @ret;
}
# i=0 is r=1
# GP-Test  i+1 + j+1 + 1 - 1 == i+j+2

my %compositions_to_end = (0       => 1,
                           append  => 1,
                           prepend => 0);
sub init {
  my ($self, %params) = @_;
  ### ExcessConfigurations init ...

  my $N = delete($params{'N'}) || 0;

  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute
    (name => "Excess Configurations N=$N");

  my @pending = ([0]);
  $graph->add_vertex('0');
  foreach (1 .. $N) {
    ### $_
    my @new_pending;
    foreach my $from (@pending) {
      my $from_str = join(',',@$from);
      foreach my $to (_step($from)) {
        my $to_str = join(',',@$to);
        unless ($graph->has_vertex($to_str)) { push @new_pending, $to; }
        $graph->add_edge($from_str,$to_str);
      }
    }
    @pending = @new_pending;
  }

  ### total vertices: scalar $graph->vertices
  ### total edges   : scalar $graph->edges

  return $graph;
}

Graph::Maker->add_factory_type('excess_configurations' => __PACKAGE__);
1;

__END__

=for stopwords Ryde ExcessConfigurations coderef undirected multigraph OEIS Svante Janson Tomasz Luczak Pittel et al unicyclic acyclic tri

=head1 NAME

Graph::Maker::ExcessConfigurations - create ExcessConfigurations graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::ExcessConfigurations;
 $graph = Graph::Maker->new ('excess_configurations', N => 7);

=head1 DESCRIPTION

C<Graph::Maker::ExcessConfigurations> creates C<Graph.pm> graphs of the
evolution of multigraph excess "configuration"s in the manner of

=over

Svante Janson, Donald E. Knuth, Tomasz Luczak, Boris Pittel, "Birth of the
Giant Component", Random Structures and Algorithms, volume 4, 1993, pages
233-358.  L<https://arxiv.org/abs/math/9310236>,
L<https://onlinelibrary.wiley.com/doi/abs/10.1002/rsa.3240040303>

=back

            /---> 0,1 --->  1,1          ( cross connections
    0 ---> 1           X                       0,1 and 2
            \--->  2  --->  0,0,1           -> 1,1 and 0,0,1 )
                    \
                     ---->  3

The "excess" of a connected component of a multigraph is

    excess = number of edges - number of vertices
           = -1 for tree (acyclic), 0 for unicyclic, ...

Janson et al take the configuration of a multigraph to be the number of
components of excess r = 1, 2, 3, etc.

    [count r=1, count r=2, ...]      vertex name such as "1,0,2"

In the ExcessConfigurations graph, each vertex is such a configuration.  An
edge is to a new configuration obtained by adding one edge to the
multigraph.  Such an edge can increase the excess of an existing component,
including raising an r=0 to a new r=1.  Or it can join two components r,s
together for new combined excess r+s+1.  r=0 components doesn't appear in
the configuration but are taken to be in unlimited supply.

Janson et al note this is a partial ordering of configurations since total
excess increases by 1 each time.  Total excess is total of the rE<gt>=0
components, so not including tree components.

    total excess = r1 + 2*r2 + 3*r3 + ...

Parameter N here is how many evolution steps, so configurations of total
excess 0 through N inclusive, and the edges between them.  Total excess is
sum of component excesses, so those component excesses are a partition of
the total.  The number of vertices is thus sum over t=total,

    num vertices = sum(t=0,N, NumPartitions(t))
                 = 1, 2, 4, 7, 12, 19, ...  (A000070)

=cut

# GP-DEFINE  numbpart_cumulative(n) = sum(t=0,n,numbpart(t));
# GP-Test  vector(6,n,n--; numbpart_cumulative(n)) == [1, 2, 4, 7, 12, 19]

=pod

=head2 Cycles

As a note on terminology, excess r=0 described above is a unicyclic
component, meaning it has one cycle and possible acyclic branches hanging
off.

Janson et al call r=1 bi-cyclic (and r=2 tri-cyclic, etc).  The cases for
r=1 are, up to paths or vertex insertions (so "reduced multigraphs"),

      _   _      __      __          __
     / \ / \    |  |    |  |        /  \         excess r=1
    |   A   |   |  A----B  |       A----B      (Janson et al
     \_/ \_/    |__|    |__|        \__/       equation 9.15)      

         separate loops          three paths

The separate loops are clearly 2 cycles.  The three paths case would be 3
cycles if all combinations were allowed.  Excess r=1 as bi-cyclic is
understood as successive cycles using at least one previously unused edge,
the way edges are added to the multigraph in forming a cycle.

=cut

# separate loops by joining two r=0 to make 0+0+1 = 1
# three paths by new edge on r=0 to make 0+1 = 1

=pod

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('excess_configurations', key =E<gt> value, ...)>

The key/value parameters are

    N           =>  integer, number of steps
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either the C<graph_maker>
coderef or C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are in the add-an-edge
direction between configurations.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for the trees here include,

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310> etc

=back

    1310    N=0, singleton
    19655   N=1, path-2
    500     N=2, star-4 claw
    33585   N=3
    33587   N=4

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this tree include

=over

L<http://oeis.org/A000070> (etc)

=back

    A000070    num vertices, cumulative num partitions
    A029859    num edges, partitions choose 0,1,2 terms
    A000041    num successorless, partitions of N

=head1 SEE ALSO

L<Graph::Maker>

=head1 LICENSE

Copyright 2018, 2019 Kevin Ryde

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
