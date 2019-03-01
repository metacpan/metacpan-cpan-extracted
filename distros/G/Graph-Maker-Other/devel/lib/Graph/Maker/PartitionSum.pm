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


package Graph::Maker::PartitionSum;
use 5.004;
use strict;
use Carp 'croak';
use List::Util 'sum';
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 13;
@ISA = ('Graph::Maker');

use Graph::Maker::BulgarianSolitaire;
*_partition_next = \&Graph::Maker::BulgarianSolitaire::_partition_next;

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


sub _any_same {
  my ($aref) = @_;
  foreach my $i (1 .. $#$aref) {
    if ($aref->[$i] == $aref->[$i-1]) { return 1; }
  }
  return 0;
}

sub init {
  my ($self, %params) = @_;
  ### PartitionSum init ...

  my $N            = delete($params{'N'}) || 0;
  my $distinct     = delete($params{'distinct'});
  my $graph        = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Partition Sum N=$N");

  my @to = (1) x $N;
  do {
    unless ($distinct && _any_same(\@to)) {
      my $to_str = join(',',@to);
      $graph->add_vertex ($to_str);
      ### $to_str

      foreach my $i (0 .. $#to) {
        next if $i && $to[$i]==$to[$i-1];  # distinct terms only
        my @to_sans = @to;
        splice @to_sans, $i,1;

        # 5 want $s = 1,2 other 4,3       so floor($to[$i]/2)
        # 6 want $s = 1,2,3 other 5,4,3
        foreach my $s (1 .. $to[$i]>>1) {
          my @from = sort {$a<=>$b} @to_sans, $s, $to[$i]-$s;
          unless ($distinct && _any_same(\@from)) {
            $graph->add_edge ($to_str,
                              join(',', @from));
          }
        }
      }
    }

    # if (@from >= 2) {
    #   my $i = 0;
    #   my $j = 1;
    # IJ: for (;;) {
    #     ### sum: "$i $j"
    #     {
    #       ### assert: $i <= $j
    #       my @to = @from;
    #       splice @to, $j,1;
    #       splice @to, $i,1;
    #       @to = sort {$a<=>$b} @to, $from[$i]+$from[$j];
    #       my $to_str = join(',',@to);
    #       ### $to_str
    #       $graph->add_edge ($from_str, $to_str);
    #     }
    #   INCR: do {
    #       $j++;
    #       if ($j > $#from) {
    #         do {
    #           $i++;
    #           if ($i > $#from-1) { last IJ; }
    #         } while ($from[$i] == $from[$i-1]);
    #         $j = $i+1;
    #         next IJ;
    #       }
    #     } while ($from[$j] == $from[$j-1]);
    #   }
    # }
  } while (_partition_next(\@to));

  ### total vertices: scalar $graph->vertices
  ### total edges   : scalar $graph->edges

  return $graph;
}

Graph::Maker->add_factory_type('partition_sum' => __PACKAGE__);
1;

__END__

=for stopwords Ryde PartitionSum coderef undirected OEIS

=head1 NAME

Graph::Maker::PartitionSum - create partition sum graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::PartitionSum;
 $graph = Graph::Maker->new ('partition_sum', N => 7);

=head1 DESCRIPTION

C<Graph::Maker::PartitionSum> creates C<Graph.pm> graphs of partitions
stepped by summing terms.

                          1,1,3 --> 1,4
                          ^    \   ^   \
                         /      \ /     v         N => 5
    1,1,1,1,1 --> 1,1,1,2        X       5
                         \      / \     ^
                          v    /   v   /
                          1,2,2 --> 2,3

Each vertex is a partition of integer N, meaning a set of integers which sum
to N.  Vertex names are the terms in ascending order, separated by commas.

=for GP-Test  vecsum([1,3,3,5]) == 12

Edges are by summing two terms in the partition to reach another.  The
number of edges is all the ways to choose two terms.

    num vertices = partitions of N
                 = 1, 1, 2, 3, 5, 7, 11, 15, ... (A000041)

    num edges    = choose 2 terms in partitions
                 = 0, 0, 1, 2, 5, 9, 17, 28, ... (A000097)

N=0 is reckoned as a single vertex which is the empty partition.  N=1 is
single vertex 1.

Each sum reduces the number of terms by 1, so the steps are a partial
ordering of the partitions.

Steps can also be thought of the other direction, taking a partition term
and split it into two.  (The current implementation forms edges that way.)

=cut

# The graph diameter, as undirected, is N-1.  Going from the N term all 1s to
# the 1 term N is N-1 steps.

=pod

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('partition_sum', key =E<gt> value, ...)>

The key/value parameters are

    N           =>  integer, to partition
    graph_maker =>  subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either the C<graph_maker>
coderef or C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added just in the sum
direction.  Option C<undirected =E<gt> 1> creates an undirected graph.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for the graphs here include

=over

=item N=0,1, L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310> singleton

=item N=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=19655> path-2

=item N=3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=32234> path-3

=item N=4, L<https://hog.grinvin.org/ViewGraphInfo.action?id=206> 4-cycle and leaf

=item N=5, L<https://hog.grinvin.org/ViewGraphInfo.action?id=864>

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
these graphs include

=over

L<http://oeis.org/A000041> (etc)

=back

    A000041    num vertices = num partitions
    A000097    num edges, partitions choose two terms

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
