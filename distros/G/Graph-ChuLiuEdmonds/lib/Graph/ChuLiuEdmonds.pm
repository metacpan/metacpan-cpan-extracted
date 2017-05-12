package Graph::ChuLiuEdmonds;

use warnings;
use strict;

=head1 NAME

Graph::ChuLiuEdmonds - Find minimum spanning trees in a directed graph.

=head1 VERSION

Version 0.05

=cut

use Carp;
our $VERSION = '0.06';
our $DEBUG=0;

=head1 SYNOPSIS

This module implements Chu-Liu-Edmonds L<[1]>,L<[2]> algorithm for finding a minimum
spanning tree (MST) in a directed graph.

    use Graph;
    use Graph::Directed;
    use Graph::ChuLiuEdmonds;

    my $graph = Graph::Directed->new(vertices=>[qw(a b c d)]);
    $graph->add_weighted_edges(qw(a b 3 c d 7 d a 2 d b 1 c a 2));
    my $msts = $graph->MST_ChuLiuEdmonds($graph);
    ...

=head1 EXPORT

None.

=head1 FUNCTIONS

=head2 MST_ChuLiuEdmonds

  my $msts = $graph->MST_ChuLiuEdmonds();

Returns a Graph object that is a forest consisting of MSTs for a given
directed graph.

Minimum Spanning Trees or MSTs are directed tree subgraphs derived
from a directed graph that "span the graph" (covering all the
vertices) using as lightly weighted (hence the "minimum") edges as
possible.

=cut

sub Graph::MST_ChuLiuEdmonds_no_copy {
  my ($graph)=@_;
  carp("graph not directed") unless $graph->is_directed;
  return _MST($graph);
}

=head2 MST_ChuLiuEdmonds_no_copy

  my $msts = $graph->MST_ChuLiuEdmonds();

Like the method above, only avoiding deep-copying the graph; the
method prunes $graph so as only the MSTs remain of it.

=cut

sub Graph::MST_ChuLiuEdmonds {
  my ($graph)=@_;
  carp("graph not directed") unless $graph->is_directed;
  return _MST($graph->deep_copy);
}

sub _MST {
  my ($g)=@_;

  my %in; # in the resulting (or partial) MST, this will map a vertex Y to the vertex X
          # in which the unique edge incoming to Y starts
          # i.e maps Y => X if X->Y is an edge of the resulting MST

  # phase 1: add best edges and contract cycles
  my $cycle_no=0;
  my @V = $g->vertices;
  print "Vertices: @V\n" if $DEBUG;
  my $_no_vertices=@V;
  my @C;
  my ($x,$y,$w,$e);
  while (@V) {
    print "Graph: $g\n" if $DEBUG;
    $y = shift @V;
    my $best_w;
    print STDERR "selecting incoming edges for vertex $y\n" if $DEBUG;
    for my $e ($g->edges_to($y)) {
      $w = $g->get_edge_weight( $e->[0], $y );
      if (!defined($best_w) or $w<$best_w) {
	$best_w=$w;
	$x=$e->[0];
      }
    }
    next unless defined $best_w;
    print STDERR "best $x-$y: $best_w\n" if $DEBUG;
    # we add the best incoming edge edge to $y
    $in{$y}=$x;
    # now we check it does not add a cycle to the MST:
    my @cycle_nodes=($y);
    my $i=0;
    do {
      unshift @cycle_nodes, $x;
      $x=$in{$x};
      die "BUG: looking for a cycle caused an infinite loop" if $i++ > $_no_vertices; # just for sure: should never happen.
    } while (defined($x) and $x ne $y);
    if (defined $x) {
      # the new edge made a cycle:
      # contract
      my $cycle = 'CYCLE:'.($cycle_no++);
      print STDERR "$cycle: @cycle_nodes\n" if $DEBUG;
      my @cycle_weights = map { 
	print STDERR "  $_: $cycle_nodes[$_-1],$cycle_nodes[$_]\n" if $DEBUG;
	$g->get_edge_weight($cycle_nodes[$_-1],$cycle_nodes[$_]) } 0..$#cycle_nodes;
      print STDERR "cycle weights: @cycle_weights\n" if $DEBUG;
      push @V,$cycle;

      $g->add_vertex($cycle); # will represent the contracted @cycle_nodes

      my %in_cycle; @in_cycle{@cycle_nodes}=();

      # for each vertex in which ends an edge starting on the cycle,
      # find the lightest edge to be preserved
      my %from=(); my %fromW=();
      for $x (@cycle_nodes) {
	for my $e ($g->edges_from($x)) {
	  $y=$e->[1];
	  next if exists $in_cycle{$y};
	  if (exists $in{$y} and exists $in_cycle{$in{$y}}) {
	    $in{$y}=$cycle;
	  }
	  $w=$g->get_edge_weight($x,$y);
	  if (!exists($fromW{$y}) or $w < $fromW{$y}) {
	    $from{$y}=$x;
	    $fromW{$y}=$w;
	  }
	}
      }
      for $y (keys %from) {
	print STDERR "adding edge $cycle -> $y weight $fromW{$y}\n" if $DEBUG;
	$g->add_weighted_edge($cycle, $y, $fromW{$y});
      }

      # Similarly for edges that end on the cycle.
      # For each such edge X->Y with Y on the cycle
      # we compute a weight as w(X->Y)+the weight of the arc
      # of the cycle starting at Y and ending on a node preceding Y
      # in the cycle. For a fixed X we find Y on the cycle
      # for which this computed weight is minimal.
      my %to;
      my %toW=(); my $i=0;
      my $C=0; $C+=$_ for @cycle_weights; # weight of the whole cycle
      for $y (@cycle_nodes) {
	for $e ($g->edges_to($y)) {
	  $x=$e->[0];
	  next if exists $in_cycle{$x};
	  $w=$g->get_edge_weight($x,$y)+$C-$cycle_weights[$i];
	  if (!exists($toW{$x}) or $w < $toW{$x}) {
	    $to{$x}=$y;
	    $toW{$x}=$w;
	  }
	}
	$i++;
      }
      for my $x (keys %to) {
	print STDERR "adding edge $x -> $cycle weight $toW{$x}\n" if $DEBUG;
	$g->add_weighted_edge($x, $cycle, $toW{$x});
      }

      # delete the nodes of the @cycle_nodes
      $g->delete_vertices(@cycle_nodes);
      delete @in{@cycle_nodes};
      push @C,[$cycle,\@cycle_nodes,\@cycle_weights,\%to,\%from,\%toW,\%fromW];
    }
  }
  # ok, now we have processed all nodes, including the nodes
  # representing the contracted cycles.
  # there is at most one incoming edge to
  # each node (and exactly one if there was
  # at least one in the original graph).

  # prune all edges that are not in the resulting (contracted) MST
  print STDERR "before phase2: $g\n" if $DEBUG;
  for $y ($g->vertices) {
    $x=$in{$y};
    $g->delete_edges(map { @$_[0,1] } grep { !defined($x) or ($_->[0] ne $x) } $g->edges_to($y));
  }
  # phase 2: expand all cycles
  print STDERR "phase2: $g\n" if $DEBUG;
  while (@C) {
    my $C = pop @C;
    my ($cycle,$cycle_nodes,$cycle_weights,$to,$from,$toW,$fromW)=@$C;

    print STDERR "expanding: $cycle\n" if $DEBUG;
    $g->add_vertices(@$cycle_nodes);

    # fix incoming edge
    ($e) = $g->edges_to($cycle); # should now be at most one
    if ($e) {
      $x=$e->[0];
      #print STDERR "incoming edge from: $x\n" if $DEBUG;
      $y = $to->{$x};
      $g->add_weighted_edge($x,$y,$toW->{$x});
      for my $i (0..$#$cycle_nodes) {
	$g->add_weighted_edge($cycle_nodes->[$i-1],$cycle_nodes->[$i],$cycle_weights->[$i]) unless $cycle_nodes->[$i] eq $y;
      }
    } else {
      # the whole graph starts at this cycle
      # find the edge with the lowest weight and disconnect there
      #print STDERR "the cycle is a root\n" if $DEBUG;
      my $max;
      my $max_i; # the worst edge on the cycle
      my $i = 0;
      for my $w (@$cycle_weights) {
	if (!defined($max) or $w>$max) {
	  $max = $w;
	  $max_i=$i;
	}
	$i++
      }
      for $i (0..$#$cycle_nodes) {
	#print "adding edge $cycle_nodes->[$i-1],$cycle_nodes->[$i] $cycle_weights->[$i] unless $i==$max_i\n" if $DEBUG;
	$g->add_weighted_edge($cycle_nodes->[$i-1],$cycle_nodes->[$i],$cycle_weights->[$i]) unless $i==$max_i;
      }
    }
    # fix outgoing edge
    for $e ($g->edges_from($cycle)) {
      $y = $e->[1];
      $x = $from->{$y};
      print STDERR "restoring edge $x -> $e->[1]\n" if $DEBUG;
      $g->add_weighted_edge($x,$y,$fromW->{$y});
    }
    $g->delete_vertex($cycle);
    print STDERR "expanded: $g\n" if $DEBUG;
  }
  # all cycles expanded, we are done!
  print STDERR "MST: $g\n" if $DEBUG;
  return $g;
}


=head1 AUTHOR

Petr Pajas, C<< <pajas at matfyz.cz> >>

=head1 CAVEATS

=over 5

=item o

The implementation was not tested on complex examples.

=item o

Vertices cannot be perl objects (or references).

=item o

Vertex and edge attributes are not copied from the source graph to the
resulting graph (except for edge weights).

=item o

The author did not attempt to compute the actual algorithmic
complexity of this particular implementation.

=item o

The algorithm implemented in this module returns the optimal MSTs. To
obtain k-best MSTs, one could implement Camerini's algorithm L<[4]>
(also described in [5]).

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-graph-chuliuedmonds at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-ChuLiuEdmonds>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Graph::ChuLiuEdmonds

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Graph-ChuLiuEdmonds>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Graph-ChuLiuEdmonds>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graph-ChuLiuEdmonds>

=item * Search CPAN

L<http://search.cpan.org/dist/Graph-ChuLiuEdmonds>

=back

=head1 SEE ALSO

The implementation follows the algorithm published by Edmonds L<[1]>
and independently Chu and Liu L<[2]>, as scatched in the 3rd section
of L<[3]>. Note that possibly more efficient implementation is
suggested in L<[3]>.

=over 4

=item [1]

J. Edmonds. 1967. Optimum branchings. Journal of Research of the
National Bureau of Standards, 71B:233-240.

=item [2]

Y.J. Chu and T.H. Liu. 1965. On the shortest arborescence of a
directed graph. Science Sinica, 14:1396-1400.

=item [3]

H. N. Gabow, Z. Galil, T. Spencer and R. E. Tarjan. 1986
Efficient algorithms for finding minimum spanning trees in undirected
and directed graphs. Combinatorica 6 (2) 109-122

=item [4]

Paolo M. Camerini, Luigi Fratta, and Francesco Maffioli. 1980.
The k best spanning arborescences of a network. Networks,
10:91-110.

=item [5]

Keith Hall. 2007. k-best spanning tree parsing.  In (To Appear)
Proceedings of the 45th Annual Meeting of the Association for
Computational Linguistics.

=back

=head1 ACKNOWLEDGEMENTS

The development of this module was supported by grant GA AV CR 1ET101120503.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Petr Pajas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Graph::ChuLiuEdmonds
