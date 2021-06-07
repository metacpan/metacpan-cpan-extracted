package Graph::Undirected::Hamiltonicity::Transforms;

use Modern::Perl;
use Carp;

use Graph::Undirected;
use Graph::Undirected::Hamiltonicity::Output qw(:all);

use Exporter qw(import);

our @EXPORT_OK = qw(
    &add_random_edges
    &delete_cycle_closing_edges
    &delete_non_required_neighbors
    &get_common_neighbors
    &get_required_graph
    &get_random_isomorph
    &string_to_graph
    &swap_vertices
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

##########################################################################

# The "required graph" contains the same vertices as the original graph,
# but with only the edges incident on vertices of degree == 2.

sub get_required_graph {
    my ($g) = @_;

    output(   "Beginning a sweep to mark all edges adjacent to degree 2 "
            . "vertices as required:<BR/>" );

    my $g1 = $g->deep_copy_graph();
    output($g1);

    my @vertices = $g1->vertices();
    my $required_graph = Graph::Undirected->new( vertices => \@vertices );

    foreach my $vertex (@vertices) {
        my $degree = $g1->degree($vertex);
        if ( $degree != 2 ) {
            output("Vertex $vertex : Degree=[$degree] ...skipping.<BR/>");
            next;
        }

        output("Vertex $vertex : Degree=[$degree] ");
        output("<UL>");
        foreach my $neighbor_vertex ( $g1->neighbors($vertex) ) {
            $required_graph->add_edge( $vertex, $neighbor_vertex );

            if ( $g1->get_edge_attribute( $vertex, $neighbor_vertex,
                                          'required') ) {
                output( "<LI>$vertex=$neighbor_vertex is already "
                        . "marked required</LI>" );
                next;
            }

            $g1->set_edge_attribute($vertex, $neighbor_vertex,
                                    'required', 1);
            output( "<LI>Marking $vertex=$neighbor_vertex "
                    . "as required</LI>" );
        }
        output("</UL>");
    }

    if ( $required_graph->edges() ) {
        output("required graph:");
        output( $required_graph, { required => 1 } );
    } else {
        output("The required graph has no edges.<BR/>");
    }

    return ( $required_graph, $g1 );
}

##########################################################################

# For each required walk, delete the edge connecting its endpoints,
# as such an edge would make the graph non-Hamiltonian, and therefore
# the edge can never be part of a Hamiltonian cycle.

sub delete_cycle_closing_edges {
    output("Entering delete_cycle_closing_edges()<BR/>");
    my ($g, $required_graph) = @_;
    my $deleted_edges = 0;
    my $g1;
    my %eliminated;

    foreach my $vertex ( $required_graph->vertices() ) {
        next unless $required_graph->degree($vertex) == 1;
        next if $eliminated{$vertex}++;

        my @reachable = $required_graph->all_reachable($vertex);

        my ( $other_vertex ) = grep { $required_graph->degree($_) == 1 } @reachable;
        $g1 //= $g->deep_copy_graph();
        next unless $g1->has_edge($vertex, $other_vertex);
        $g1->delete_edge($vertex, $other_vertex);
        $required_graph->delete_edge($vertex, $other_vertex);
        $deleted_edges++;

        output( "Deleted edge $vertex=$other_vertex"
                . ", between endpoints of a required walk.<BR/>" );
    }

    if ( $deleted_edges ) {
        my $s = $deleted_edges == 1 ? '' : 's';
        output("Shrank the graph by removing $deleted_edges edge$s.<BR/>");
        return ( $deleted_edges, $g1 );
    } else {
        output("Did not shrink the graph.<BR/>");
        return ( $deleted_edges, $g );
    }
}

##########################################################################

sub delete_non_required_neighbors {
    output("Entering delete_non_required_neighbors()<BR/>");

    my ( $g, $required_graph ) = @_;
    my $g1;
    my $deleted_edges = 0;
    foreach my $required_vertex ( $required_graph->vertices() ) {
        next if $required_graph->degree($required_vertex) != 2;
        foreach my $neighbor_vertex ( $g->neighbors($required_vertex) ) {
            my $required =
                $g->get_edge_attribute( $required_vertex,
                                        $neighbor_vertex, 'required' );
            next if $required;
            ### Clone graph lazily
            $g1 //= $g->deep_copy_graph();

            next
                unless $g1->has_edge(
                    $required_vertex, $neighbor_vertex );

            $g1->delete_edge( $required_vertex, $neighbor_vertex );
            $deleted_edges++;
            output( "Deleted edge $required_vertex=$neighbor_vertex "
                    . "because vertex $required_vertex has degree==2 "
                    . "in the required graph.<BR/>" );
        }
    }

    if ( $deleted_edges ) {
        my $s = $deleted_edges == 1 ? '' : 's';
        output("Shrank the graph by removing $deleted_edges edge$s.<BR/>");
        return ( $deleted_edges, $g1 );
    } else {
        output("Did not shrink the graph.<BR/>");
        return ( $deleted_edges, $g );
    }
}

##########################################################################

sub swap_vertices {
    my ( $g, $vertex_1, $vertex_2 ) = @_;
    my $g1 = $g->deep_copy_graph();

    my %common_neighbors =
        %{ get_common_neighbors( $g1, $vertex_1, $vertex_2 ) };

    my @vertex_1_neighbors =
        grep { $_ != $vertex_2 } $g1->neighbors($vertex_1);
    my @vertex_2_neighbors =
        grep { $_ != $vertex_1 } $g1->neighbors($vertex_2);

    foreach my $neighbor_vertex (@vertex_1_neighbors) {
        next if $common_neighbors{$neighbor_vertex};
        $g1->delete_edge( $neighbor_vertex, $vertex_1 );
        $g1->add_edge( $neighbor_vertex, $vertex_2 );
    }

    foreach my $neighbor_vertex (@vertex_2_neighbors) {
        next if $common_neighbors{$neighbor_vertex};
        $g1->delete_edge( $neighbor_vertex, $vertex_2 );
        $g1->add_edge( $neighbor_vertex, $vertex_1 );
    }

    return $g1;
}

##########################################################################

sub get_common_neighbors {
    my ( $g, $vertex_1, $vertex_2 ) = @_;
    my %common_neighbors;
    my %vertex_1_neighbors;
    foreach my $neighbor_vertex ( $g->neighbors($vertex_1) ) {
        $vertex_1_neighbors{$neighbor_vertex} = 1;
    }

    foreach my $neighbor_vertex ( $g->neighbors($vertex_2) ) {
        next unless $vertex_1_neighbors{$neighbor_vertex};
        $common_neighbors{$neighbor_vertex} = 1;
    }

    return \%common_neighbors;
}

##########################################################################

# Takes a string representation of a Graph::Undirected
# The string is the same format as the result of calling the stringify()
# method on a Graph::Undirected object.
#
# Returns a Graph::Undirected object, constructed from its string form.

sub string_to_graph {
    my ($string) = @_;
    my %vertices;
    my @edges;

    foreach my $chunk ( split( /\,/, $string ) ) {
        if ( $chunk =~ /=/ ) {
            my @endpoints = map {s/\b0+([1-9])/$1/gr}
                split( /=/, $chunk );

            next if $endpoints[0] == $endpoints[1];
            push @edges, \@endpoints;
            $vertices{ $endpoints[0] } = 1;
            $vertices{ $endpoints[1] } = 1;
        } else {
            $vertices{$chunk} = 1;
        }
    }

    my @vertices = keys %vertices;
    my $g = Graph::Undirected->new( vertices => \@vertices );

    foreach my $edge_ref (@edges) {
        $g->add_edge(@$edge_ref) unless $g->has_edge(@$edge_ref);
    }

    return $g;
}

##########################################################################

# Takes a Graph::Undirected ( $g )
#
# Returns a Graph::Undirected  ( $g1 ) which is an isomorph of $g

sub get_random_isomorph {
    my ($g) = @_;

    # everyday i'm shufflin'

    my $g1 = $g->deep_copy_graph();
    my $v  = scalar( $g1->vertices() );

    my $max_times_to_shuffle = $v * $v;
    my $shuffles             = 0;
    while ( $shuffles < $max_times_to_shuffle ) {
        my $v1 = int( rand($v) );
        my $v2 = int( rand($v) );

        next if $v1 == $v2;

        $g1 = swap_vertices( $g1, $v1, $v2 );
        $shuffles++;
    }

    return $g1;
}

##############################################################################

sub add_random_edges {
    my ( $g, $edges_to_add ) = @_;

    my $e  = scalar( $g->edges() );
    my $v  = scalar( $g->vertices() );
    my $max_edges = ( $v * $v - $v ) / 2;

    if ( ($e + $edges_to_add) > $max_edges ) {
        croak "Can only add up to: ", $max_edges - $e, 
              " edges. NOT [$edges_to_add]; e=[$e]\n";
    }

    my $g1 = $g->deep_copy_graph();
    my $added_edges = 0;
    while ( $added_edges < $edges_to_add ) {
        my $v1 = int( rand($v) );
        my $v2 = int( rand($v) );

        next if $v1 == $v2;
        next if $g1->has_edge( $v1, $v2 );

        $g1->add_edge( $v1, $v2 );
        $added_edges++;
    }

    return $g1;
}

##############################################################################


1;    # End of Graph::Undirected::Hamiltonicity::Transforms
