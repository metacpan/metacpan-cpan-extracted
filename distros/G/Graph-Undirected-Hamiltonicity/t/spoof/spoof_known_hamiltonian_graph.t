#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity;
use Graph::Undirected::Hamiltonicity::Spoof
    qw(&spoof_known_hamiltonian_graph);

use Test::More;
use Test::Exception;

plan tests => 58;

$ENV{HC_OUTPUT_FORMAT} = 'none';

throws_ok { my $g = spoof_known_hamiltonian_graph(0); }
qr/Please provide the number of vertices/,
    "Trying to spoof a Hamiltonian graph with 0 vertices.";

throws_ok { my $g = spoof_known_hamiltonian_graph(2); }
qr/A graph with 2 vertices cannot be Hamiltonian/,
    "Trying to spoof a Hamiltonian graph with 2 vertices.";

throws_ok { my $g = spoof_known_hamiltonian_graph( 8, 5 ); }
qr/The number of edges must be >= number of vertices/,
    "Trying to spoof a Hamiltonian graph more vertices than edges.";

for my $v ( 3 .. 13 ) {
    my $g = spoof_known_hamiltonian_graph($v);
    is( scalar( $g->vertices() ), $v, "Spoofed graph has $v vertices." );
    my $is_hamiltonian = graph_is_hamiltonian($g);
    is( $is_hamiltonian, 1, "Spoofed graph is Hamiltonian" );
}

for my $v ( 10 .. 20 ) {
    my $e = 2 * $v;
    my $g = spoof_known_hamiltonian_graph( $v, $e );
    is( scalar( $g->vertices() ), $v, "Spoofed graph has $v vertices." );
    is( scalar( $g->edges() ),    $e, "Spoofed graph has $e edges." );
    my $is_hamiltonian = graph_is_hamiltonian($g);
    is( $is_hamiltonian, 1, "Spoofed graph is Hamiltonian." );
}

