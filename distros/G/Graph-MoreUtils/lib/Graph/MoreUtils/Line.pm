package Graph::MoreUtils::Line;

# ABSTRACT: Generate line graphs
our $VERSION = '0.1.0'; # VERSION

use strict;
use warnings;

use Graph::MoreUtils::Line::SelfLoopVertex;
use Graph::Undirected;
use Scalar::Util qw( blessed );

sub line
{
    my( $graph, $options ) = @_;

    if( !blessed $graph || !$graph->isa( Graph::Undirected:: ) ) {
        die 'only Graph::Undirected and its derivatives are accepted' . "\n";
    }

    $options = {} unless $options;

    # Collect all edges prior to converting them to vertices:
    my @originals;
    my @new_vertices;
    if( $graph->is_multiedged ) {
        for my $unique_edge ($graph->unique_edges) {
            for my $edge ($graph->get_multiedge_ids( @$unique_edge )) {
                push @originals, $unique_edge;
                push @new_vertices,
                     $graph->get_edge_attributes_by_id( @$unique_edge,
                                                        $edge ) || {};
            }
        }
    } else {
        # Have to do this in for cycle to maintain relation between the
        # parallel arrays:
        for my $edge ($graph->edges) {
            push @originals, $edge;
            push @new_vertices,
                 $graph->get_edge_attributes( @$edge ) || {};
        }
    }

    # Collect adjacent edges for every vertice
    my $adjacency = {};
    for my $i (0..$#originals) {
        push @{$adjacency->{$originals[$i]->[0]}}, $new_vertices[$i];

        # Self-loops have to be detected and not added once again
        next if $originals[$i]->[0] eq $originals[$i]->[1];

        push @{$adjacency->{$originals[$i]->[1]}}, $new_vertices[$i];
    }

    # Create the line graph
    my $line_graph = Graph::Undirected->new( refvertexed => 1 );
    $line_graph->add_vertices( @new_vertices );
    for my $vertex (sort keys %$adjacency) {
        for my $i (0..$#{$adjacency->{$vertex}}-1) {
            for my $j ($i+1..$#{$adjacency->{$vertex}}) {
                $line_graph->set_edge_attribute( $adjacency->{$vertex}[$i],
                                                 $adjacency->{$vertex}[$j],
                                                 'original_vertex',
                                                 $vertex );
            }
        }
    }

    # Add self-loops for end vertices if requested
    if( $options->{loop_end_vertices} ) {
        for my $vertex ($graph->vertices) {
            next if $graph->degree( $vertex ) != 1;
            # Adjacency matrix will only have one item
            $line_graph->set_edge_attribute( $adjacency->{$vertex}[0],
                                             Graph::MoreUtils::Line::SelfLoopVertex->new,
                                             'original_vertex',
                                             $vertex );
        }
    }

    return $line_graph;
}

1;
