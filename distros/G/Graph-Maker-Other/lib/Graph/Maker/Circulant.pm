# Copyright 2018, 2019, 2020, 2021 Kevin Ryde
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

package Graph::Maker::Circulant;
use 5.004;
use strict;
use Graph::Maker;
use List::Util 'min';

use vars '$VERSION','@ISA';
$VERSION = 18;
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

sub init {
  my ($self, %params) = @_;

  my $N = delete($params{'N'}) || 0;
  my $offset_list = delete($params{'offset_list'});
  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute
    (name => "Circulant $N Offset ".join(',',@$offset_list));

  my $directed = $graph->is_directed;
  $graph->add_vertices(1 .. $N);
  my %seen;
  my $half = $N/2;
  foreach my $o (@$offset_list) {
    my $o = min($o%$N, (-$o)%$N);
    next if $seen{$o}++;
    foreach my $from (1 .. ($o==$half ? $half : $N)) {
      my $to = ($from + $o - 1) % $N + 1;  # 1 to N modulo
      $graph->add_edge($from,$to);
      if ($directed && $o) { $graph->add_edge($to,$from); }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('circulant' => __PACKAGE__);
1;

__END__

=for stopwords Ryde circulant coprime Circulant undirected octohedral Mobius

=head1 NAME

Graph::Maker::Circulant - create circulant graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Circulant;
 $graph = Graph::Maker->new ('circulant', N=>8, offset_list=>[1,4]);

=head1 DESCRIPTION

C<Graph::Maker::Circulant> creates C<Graph.pm> circulant graphs.  The graph
has vertices 1 to N.  Each vertex v has an edge to v+offset, for each offset
in the given C<offset_list>.  v+offset is taken mod N in the range 1 to N.

Offsets will usually be 1 E<lt>= offset E<lt>= N/2.  Anything bigger can be
reduced mod N, and any bigger than N/2 is equivalent to some -offset, and
that is equivalent to an edge v-offset to v.  Offset 0 means a self-loop at
each vertex.

A single C<offset_list =E<gt> [1]> gives a cycle the same as
L<Graph::Maker::Cycle>.  Bigger single offset is a cycle with vertices in a
different order, or if offset and N have a common factor then multiple
cycles.

In general, if N and all offsets have a common factor g then the effect is g
many copies of circulant N/g and offsets/g.

A full C<offset_list> 1..N/2 is the complete graph the same as
L<Graph::Maker::Complete>.

If a factor m coprime to N is put through all C<offset_list> then the
resulting graph is isomorphic.  Edges are m*v to m*v+m*offset which is the
same by identifying m*v in the multiple with v in plain.  For example
circulant N=8 offsets 1,4 is isomorphic to offsets 3,4, the latter being
multiple m=3.  If an offset list doesn't have 1 but does have some offset
coprime to N then dividing through mod N gives an isomorphic graph with 1 in
the list.

Circulant N=6 2,3 is isomorphic to the rook grid 3x2 per
L<Graph::Maker::RookGrid>.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('circulant', key =E<gt> value, ...)>

The key/value parameters are

    N           => integer, number of vertices
    offset_list => arrayref of integers
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both ways
between vertices.  Option C<undirected =E<gt> 1> creates an undirected graph
and for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here, excluding cycles and completes,
include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=226>  etc

=back

    74      N=4 1,2     tetrahedral

    226     N=6 1,2     octohedral
    84      N=6 1,3     complete bipartite 3,3
    746     N=6 2,3     circular ladder 3 rungs

    710     N=7 1,2
    58      N=7 1,2,3

    160     N=8 1,2
    570     N=8 1,3
    176     N=8 1,2,3      sixteen cell
    36263   N=8 1,2,4
    33454   N=8 1,3,4
    180     N=8 1,2,3,4
    640     N=8 1,4        Mobius ladder 4 rungs
    116     N=8 2,4        two complete-4s

    328     N=9 1,3
    33801   N=9 1,2,3      symmetric configuration
    370     N=9 1,2,4
    328     N=9 1,2,3,4

    21063   N=10 1,2
    32519   N=10 1,3
    36276   N=10 1,5       Mobius ladder 5 rungs
    138     N=10 2,4       two complete-5
    36274   N=10 2,5
    21117   N=10 1,2,4     cross-linked complete-5s
    148     N=10 1,2,3,4
    152     N=10 1,2,3,4,5
    20611   N=10 1,2,5
    252     N=10 1,3,5
    142     N=10 1,2,3,5
    32441   N=10 2,4,5  

    21065   N=13 1,5       cyclotomic
    19514   N=13 1,2,5

    20688   N=16 1,2,5,8
    30395   N=17 1,2,4,8   a Ramsey 4,4

=cut

# More by grepping
#
# Many N=12 from integral graphs maybe
#
# HOG N=20 2,5,6 not shown in POD, num edges 60 (out of 190)
# SsaCA_hHPEE?QFPJGUb??BpC[Gosa_lC_
#
# HOG N=20 1,3,8,10 not shown in POD, num edges 70 (out of 190)
# SsaCC?G@GQ_tETHijIjLS]T@ugBu_Bn??
#
# HOG N=20 1,4,6,9 not shown in POD, num edges 80 (out of 190)
# SsaCCA?]BoN?]?@~_~oN{@~`~_B~?B~??
#
# HOG N=21 1,4,6 not shown in POD, num edges 63 (out of 210)
# TsaC?CCCWRAPBDGaGaIbEIXHT@@T@JcS@kS?
#
# HOG N=22 1,3,8,10 not shown in POD, num edges 88 (out of 231)
# UsaCCA?WB?BBEEX`koorrE]XfeBNK?~o?^w?^w??
#
# HOG N=24 1,6,10 not shown in POD, num edges 72 (out of 276)
# WsaC??@@OD@_C`IEIB?ooDGOJ?iHChEGoca_OpOJQS?ME_?
#
# HOG N=24 2,3,10 not shown in POD, num edges 72 (out of 276)
# WsaC????oHEBQEQEEBAIGGgcQ`OTG@IACTAAOgGWY@WNK??
#
# HOG N=24 1,3,7,12 not shown in POD, num edges 84 (out of 276)
# WsaCC?H@aOgIOgPGIEB@_F@ciD`WL?eQcTISGqY@qe?Et_?
#
# HOG N=24 1,4,7,9,12 not shown in POD, num edges 108 (out of 276)
# WsaCCA?_B_M?[?Bb`po[[[[\pprbb_^{?N}?B~_B~_?N}??
#
# HOG N=26 2,10 not shown in POD, num edges 52 (out of 325)
# Ys_?GGC@?C?B?Q?H_QOEA?MC@ca???O?C_?AC??YO?@K??AE??`K??Q?
#
# HOG N=26 1,5,8,12 not shown in POD, num edges 104 (out of 325)
# YsaCCA?OI@?W?oBF`bp_{KF`o`b`BAXK@Ke?BoF_]?{EZ?KKu?W^w???
#
# HOG N=28 1,3,7,12 not shown in POD, num edges 112 (out of 378)
# [saCCA?GIAAIAJAeAb?ooIB@OQ?F@wJAwJ?cDGQJHI`KWUAY`GS\?ogDt__AmcO?
#
# HOG N=28 2,6,7,10 not shown in POD, num edges 112 (out of 378)
# [saCCA?S@OcaGcGSCE@_?Q@|CJqCZaA\`?nOW???^__bwCEFgOSFW_cB[_a?nOO_
#
# HOG N=29 1,3,7,12 not shown in POD, num edges 116 (out of 406)
# \saCCA??gH?i?qPC@HH@EC`KWf@gdASWd`WKCWOQB?S@oAFH_HEMbOAJJA?R`L?GZCaC?
#
# HOG N=30 1,3,9,14 not shown in POD, num edges 120 (out of 435)
# ]saCCA?P@CaQBBAcGOPGGDA?Goy@EpAJOPHo?{e?JZ??s?K@o@_MSG`LC`CQpOaC[Op@@w??]?

=pod

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Cycle>,
L<Graph::Maker::Complete>,
L<Graph::Maker::RookGrid>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2018, 2019, 2020, 2021 Kevin Ryde

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
