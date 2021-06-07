#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity::Spoof
    qw(&spoof_canonical_hamiltonian_graph);
use Graph::Undirected::Hamiltonicity::Tests
    qw(&test_canonical $GRAPH_IS_HAMILTONIAN $GRAPH_IS_NOT_HAMILTONIAN);

use Test::More;

plan tests => 30;

$ENV{HC_OUTPUT_FORMAT} = 'none';

for my $v ( 1 .. 10 ) {
    my $g = spoof_canonical_hamiltonian_graph($v);

    is( scalar( $g->vertices() ), $v, "Spoofed graph has $v vertices." );
    my ( $is_hamiltonian, $reason ) = test_canonical($g);

    if ( $v == 2 ) {
        is( scalar( $g->edges() ), 1, "Spoofed graph has 1 edge." );
    } else {
        is( scalar( $g->edges() ), $v, "Spoofed graph has $v edges." );
    }

    ### The result is counter-intuitive, for v == 2, but it makes sense in context.
    is( $is_hamiltonian, $GRAPH_IS_HAMILTONIAN,
        "Spoofed graph is a canonical Hamiltonian Cycle." );

}
