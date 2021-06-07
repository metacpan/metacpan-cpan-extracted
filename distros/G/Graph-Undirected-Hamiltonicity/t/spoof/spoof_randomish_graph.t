#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity::Spoof
    qw(&spoof_randomish_graph);

use Test::More;

plan tests => 286;

$ENV{HC_OUTPUT_FORMAT} = 'none';

for my $v ( 3 .. 13 ) {
    my $g = spoof_randomish_graph($v);
    is( scalar( $g->vertices() ), $v, "Spoofed random graph has $v vertices." );
    foreach my $vertex ( $g->vertices() ) {
        cmp_ok( $g->degree($vertex), '>', 1, "Degree of each vertex is > 1");
    }
}

for my $v ( 10 .. 20 ) {
    my $max_edges = ( $v * $v - $v ) / 2;
    my $e = int( rand( $max_edges ) );

    my $g = spoof_randomish_graph( $v, $e );
    is( scalar( $g->vertices() ), $v, "Spoofed random graph has $v vertices." );
    cmp_ok( scalar( $g->edges() ), '>=', $e, "Spoofed random graph has $e or more edges." );

    foreach my $vertex ( $g->vertices() ) {
        cmp_ok( $g->degree($vertex), '>', 1, "The degree of each vertex is > 1");
    }
}

