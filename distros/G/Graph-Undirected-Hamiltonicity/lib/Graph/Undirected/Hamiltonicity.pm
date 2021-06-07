package Graph::Undirected::Hamiltonicity;

# ABSTRACT: decide whether a given Graph::Undirected contains a Hamiltonian Cycle.

# You can get documentation for this module with this command:
#    perldoc Graph::Undirected::Hamiltonicity

use Modern::Perl;

use Graph::Undirected::Hamiltonicity::Output qw(&output);
use Graph::Undirected::Hamiltonicity::Tests qw(:all);
use Graph::Undirected::Hamiltonicity::Transforms qw(:all);

use Exporter qw(import);

our $VERSION     = '0.01';
our @EXPORT      = qw(graph_is_hamiltonian);    # exported by default
our @EXPORT_OK   = qw(graph_is_hamiltonian);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $calls = 0; ### Number of calls to is_hamiltonian()

##########################################################################

# graph_is_hamiltonian()
#
# Takes a Graph::Undirected object.
#
# Returns
#         1 if the given graph contains a Hamiltonian Cycle.
#         0 otherwise.
#

sub graph_is_hamiltonian {
    my ($g) = @_;

    $calls = 0;
    my ( $is_hamiltonian, $reason );
    my $time_begin = time;
    my @once_only_tests = ( \&test_trivial, \&test_dirac );
    foreach my $test_sub (@once_only_tests) {
        ( $is_hamiltonian, $reason ) = &$test_sub($g);
        last unless $is_hamiltonian == $DONT_KNOW;
    }

    my $params = {
        transformed => 0,
        tentative   => 0,
    };

    if ( $is_hamiltonian == $DONT_KNOW ) {
        ( $is_hamiltonian, $reason, $params ) = is_hamiltonian($g, $params);
    } else {
        my $spaced_string = $g->stringify();
        $spaced_string =~ s/\,/, /g;
        output("<HR NOSHADE>");
        output("In graph_is_hamiltonian($spaced_string)");
        output($g);
    }
    my $time_end = time;

    $params->{time_elapsed} = int($time_end - $time_begin);
    $params->{calls}        = $calls;

    my $final_bit = ( $is_hamiltonian == $GRAPH_IS_HAMILTONIAN ) ? 1 : 0;
    return wantarray ? ( $final_bit, $reason, $params ) : $final_bit;
}

##########################################################################

# is_hamiltonian()
#
# Takes a Graph::Undirected object.
#
# Returns a result ( $is_hamiltonian, $reason )
# indicating whether the given graph contains a Hamiltonian Cycle.
#
#

sub is_hamiltonian {
    my ($g, $params) = @_;
    $calls++;

    my $spaced_string = $g->stringify();
    $spaced_string =~ s/\,/, /g;
    output("<HR NOSHADE>");
    output("Calling is_hamiltonian($spaced_string)");
    output($g);

    my ( $is_hamiltonian, $reason );
    my @tests_1 = (
        \&test_ore,
        \&test_min_degree,
        \&test_articulation_vertex,
        \&test_graph_bridge,
    );

    foreach my $test_sub (@tests_1) {
        ( $is_hamiltonian, $reason ) = &$test_sub($g, $params);
        return ( $is_hamiltonian, $reason, $params )
            unless $is_hamiltonian == $DONT_KNOW;
    }

    ### Create a graph made of only required edges.
    my $required_graph;
    ( $required_graph, $g ) = get_required_graph($g);

    if ( $required_graph->edges() ) {
        my @tests_2 = (
            \&test_required_max_degree,
            \&test_required_connected,
            \&test_required_cyclic );
        foreach my $test_sub (@tests_2) {
            ( $is_hamiltonian, $reason, $params ) = &$test_sub($required_graph, $g, $params);
            return ( $is_hamiltonian, $reason, $params )
                unless $is_hamiltonian == $DONT_KNOW;
        }

        ### Delete edges that can be safely eliminated so far.
        my ( $deleted_edges , $g1 ) = delete_cycle_closing_edges($g, $required_graph);
        my ( $deleted_edges2, $g2 ) = delete_non_required_neighbors($g1, $required_graph);
        if ($deleted_edges || $deleted_edges2) {
            $params->{transformed} = 1;
            @_ = ($g2, $params);
            goto &is_hamiltonian;
        }
    }

    ### If there are undecided vrtices, choose between them recursively.
    my @undecided_vertices = grep { $g->degree($_) > 2 } $g->vertices();
    if (@undecided_vertices) {
        unless ( $params->{tentative} ) {
            output(  "Now running an exhaustive, recursive,"
                     . " and conclusive search,"
                     . " only slightly better than brute force.<BR/>" );
        }

        my $vertex =
            get_chosen_vertex( $g, $required_graph, \@undecided_vertices );

        my $tentative_combinations =
            get_tentative_combinations( $g, $required_graph, $vertex );

        foreach my $tentative_edge_pair (@$tentative_combinations) {
            my $g1 = $g->deep_copy_graph();
            output("For vertex: $vertex, protecting " .
                    ( join ',', map {"$vertex=$_"} @$tentative_edge_pair ) .
                   "<BR/>" );
            foreach my $neighbor ( $g1->neighbors($vertex) ) {
                next if $neighbor == $tentative_edge_pair->[0];
                next if $neighbor == $tentative_edge_pair->[1];
                output("Deleting edge: $vertex=$neighbor<BR/>");
                $g1->delete_edge( $vertex, $neighbor );
            }

            output(   "The Graph with $vertex=" . $tentative_edge_pair->[0]
                    . ", $vertex=" . $tentative_edge_pair->[1]
                    . " protected:<BR/>" );
            output($g1);

            $params->{tentative} = 1;
            ( $is_hamiltonian, $reason, $params ) = is_hamiltonian($g1, $params);
            if ( $is_hamiltonian == $GRAPH_IS_HAMILTONIAN ) {
                return ( $is_hamiltonian, $reason, $params );
            }
            output("...backtracking.<BR/>");
        }
    }

    return ( $GRAPH_IS_NOT_HAMILTONIAN,
             "The graph passed through an exhaustive search " .
             "for Hamiltonian Cycles.", $params );

}

##########################################################################

sub get_tentative_combinations {

    # Generate all allowable combinations of 2 edges,
    # incident on a given vertex.

    my ( $g, $required_graph, $vertex ) = @_;
    my @tentative_combinations;
    my @neighbors = sort { $a <=> $b } $g->neighbors($vertex);
    if ( $required_graph->degree($vertex) == 1 ) {
        my ($fixed_neighbor) = $required_graph->neighbors($vertex);
        foreach my $tentative_neighbor (@neighbors) {
            next if $fixed_neighbor == $tentative_neighbor;
            push @tentative_combinations,
                [ $fixed_neighbor, $tentative_neighbor ];
        }
    } else {
        for ( my $i = 0; $i < scalar(@neighbors) - 1; $i++ ) {
            for ( my $j = $i + 1; $j < scalar(@neighbors); $j++ ) {
                push @tentative_combinations,
                    [ $neighbors[$i], $neighbors[$j] ];
            }
        }
    }

    return \@tentative_combinations;
}

##########################################################################

sub get_chosen_vertex {
    my ( $g, $required_graph, $undecided_vertices ) = @_;

    # 1. Choose the vertex with the highest degree first.
    #
    # 2. If degrees are equal, prefer vertices which already have
    #    a required edge incident on them.
    #
    # 3. Break a tie from rules 1 & 2, by picking the lowest
    #    numbered vertex first.

    my $chosen_vertex;
    my $chosen_vertex_degree;
    my $chosen_vertex_required_degree;
    foreach my $vertex (@$undecided_vertices) {
        my $degree          = $g->degree($vertex);
        my $required_degree = $required_graph->degree($vertex);
        if (   ( !defined $chosen_vertex_degree )
            or ( $degree > $chosen_vertex_degree )
            or (    ( $degree == $chosen_vertex_degree )
                and ( $required_degree > $chosen_vertex_required_degree ) )
            or (    ( $degree == $chosen_vertex_degree )
                and ( $required_degree == $chosen_vertex_required_degree )
                and ( $vertex < $chosen_vertex ) )
            )
        {
            $chosen_vertex                 = $vertex;
            $chosen_vertex_degree          = $degree;
            $chosen_vertex_required_degree = $required_degree;
        }
    }

    return $chosen_vertex;
}

##########################################################################

1;    # End of Graph::Undirected::Hamiltonicity
