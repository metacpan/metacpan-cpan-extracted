package Graph::Undirected::Hamiltonicity::Spoof;

use Modern::Perl;
use Carp;

use Graph::Undirected;
use Graph::Undirected::Hamiltonicity::Transforms qw(&add_random_edges &get_random_isomorph);

use Exporter qw(import);

our @EXPORT_OK = qw(
    &spoof_canonical_hamiltonian_graph
    &spoof_known_hamiltonian_graph
    &spoof_random_graph
    &spoof_randomish_graph
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK, );

our $VERSION = '0.012';

##############################################################################

sub spoof_canonical_hamiltonian_graph {
    my ($v) = @_;

    my $last_vertex = $v - 1;
    my @vertices    = ( 0 .. $last_vertex );

    my $g = Graph::Undirected->new( vertices => \@vertices );
    $g->add_edge( 0, $last_vertex );

    for ( my $i = 0; $i < $last_vertex; $i++ ) {
        $g->add_edge( $i, $i + 1 );
    }

    return $g;
}

##############################################################################

sub spoof_known_hamiltonian_graph {
    my ( $v, $e ) = @_;

    croak "Please provide the number of vertices." unless defined $v and $v;
    croak "A graph with 2 vertices cannot be Hamiltonian." if $v == 2;

    $e ||= get_random_edge_count($v);

    croak "The number of edges must be >= number of vertices." if $e < $v;

    my $g = spoof_canonical_hamiltonian_graph($v);
    $g = get_random_isomorph($g);
    $g = add_random_edges( $g, $e - $v ) if ( $e - $v ) > 0;

    return $g;
}

##############################################################################

sub spoof_random_graph {

    my ( $v, $e ) = @_;
    $e //= get_random_edge_count($v);

    my $g = Graph::Undirected->new( vertices => [ 0 .. $v-1 ] );
    $g = add_random_edges( $g, $e ) if $e;

    return $g;
}

##############################################################################

sub spoof_randomish_graph {

    my ( $v, $e ) = @_;
    $e ||= get_random_edge_count($v);

    my $g = spoof_random_graph( $v, $e );

    ### Seek out vertices with degree < 2
    ### and add random edges to them.
    my $edges_to_remove = 0;
    foreach my $vertex1 ( $g->vertices() ) {
        my $degree = $g->degree($vertex1);

        next if $degree > 1;
        my $added_edges = 0;
        while ( $added_edges < (2 - $degree) ) {
            my $vertex2 = int( rand($v) );
            next if $vertex1 == $vertex2;
            next if $g->has_edge($vertex1, $vertex2);
            $g->add_edge($vertex1,$vertex2);
            $added_edges++;
            $edges_to_remove++;
        }
    }

    my $try_count = 0;
    my $max_tries = 2 * $edges_to_remove;
    ### Seek out vertices with degree > 2
    ### with neighbor of degree < 3
    ### and delete edges.
    ### Try to delete the same number of edges,
    ### as the random edges added.
    while ( $edges_to_remove and ($try_count < $max_tries) ) {
        $try_count++;
      LOOP:
        foreach my $vertex1 ( $g->vertices() ) {
            next if $g->degree($vertex1) < 3;

            foreach my $vertex2 ( $g->neighbors($vertex1) ) {
                next if $g->degree($vertex2) < 3;
                $g->delete_edge($vertex1,$vertex2);
                $edges_to_remove--;
                last LOOP;
            }
        }
    }

    carp "Exiting with $edges_to_remove extra edges.\n" if $edges_to_remove;

    return $g;
}

##############################################################################

sub get_random_edge_count {
    my ( $v ) = @_;

    my %h = ( 0 => 0, 1 => 0, 2 => 1, 3 => 3, 4 => 4 );
    my $e = $h{$v};
    return $e if defined $e;

    my $max_edges = ( $v * $v - $v ) / 2;
    my $range = $max_edges - 2 * $v + 2;
    $e = int( rand( $range ) ) + $v;

    return $e;
}

##############################################################################

1;    # End of Graph::Undirected::Hamiltonicity::Spoof
