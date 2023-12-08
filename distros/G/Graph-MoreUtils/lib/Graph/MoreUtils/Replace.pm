package Graph::MoreUtils::Replace;

# ABSTRACT: Replace one on more vertices with a given one.
our $VERSION = '0.2.0'; # VERSION

use strict;
use warnings;

use Set::Object qw( set );

sub replace
{
    my( $graph, $new, @old ) = @_;

    $graph->add_vertex( $new );

    my $old = set( @old );
    for my $edge (grep { ($old->has( $_->[0] ) && !$old->has( $_->[1] )) ||
                         ($old->has( $_->[1] ) && !$old->has( $_->[0] )) }
                       $graph->edges) {
        my( $vertex, $neighbour ) = $old->has( $edge->[0] ) ? @$edge : reverse @$edge;
        next if $graph->has_edge( $new, $neighbour );
        $graph->add_edge( $new, $neighbour );
        next unless $graph->has_edge_attributes( @$edge );
        $graph->set_edge_attributes( $new, $neighbour, $graph->get_edge_attributes( @$edge ) );
    }
    $graph->delete_vertices( @old );

    return $graph;
}

1;
