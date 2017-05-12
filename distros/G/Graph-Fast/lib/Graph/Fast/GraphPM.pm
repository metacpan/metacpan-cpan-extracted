package Graph::Fast::GraphPM;

use strict;
use warnings;
use base 'Graph::Fast';

sub noop { 1; }

*add_weighted_edge = \&Graph::Fast::add_edge;

sub add_edge {
	Graph::Fast::add_edge($_[0], $_[1], $_[2], 1);
}

*SP_Dijkstra = \&Graph::Fast::dijkstra;

*SPT_Dijkstra_clear_cache =
*SPT_Bellman_Ford_clear_cache =
	\&noop;

1;

package Graph::Fast_LPQ::GraphPM;

use base 'Graph::Fast::GraphPM';

sub has_lpq { Graph::Fast::GraphPM->new(queue_maker => sub { List::PriorityQueue->new() }); }

sub no_lpq { print STDERR "Creating Graph::Fast_LPQ::GraphPM with Hash::PriorityQueue because List::PriorityQueue isn't installed.\n";
	Graph::Fast::GraphPM->new(); }

eval { require List::PriorityQueue };
if ($@) {
	*new = \&no_lpq;
} else {
	*new = \&has_lpq;
}

1;


__END__

=head1 NAME

Graph::Fast::GraphPM - Graph.pm compatibility routines for Graph::Fast

=head1 SYNOPSIS

 my $g = new Graph::Fast::GraphPM;
 # use $g like Graph::Directed

=head1 DESCRIPTION

This module exposes a L<Graph> style interface to L<Graph::Fast>, allowing
existing applications using L<Graph::Directed> to use Fastgraph without
changes.

=head1 LIMITATIONS

Not all functions are implemented yet.

Certain esoteric features like hypergraphs will probably never be emulated.

=head1 SEE ALSO

L<Graph> for the interface

=head1 AUTHORS & COPYRIGHTS

Made 2009 by Lars Stoltenow. No rights reserved. Do what the fuck you want.
(Credit is appreciated, though)

=cut
