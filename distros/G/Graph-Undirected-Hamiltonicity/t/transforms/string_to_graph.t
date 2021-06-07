#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity::Transforms qw(&string_to_graph);

use Test::More;

plan tests => 24;

my $herschel_graph_text =
    '0=1,0=10,0=3,0=9,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9';

my @tests = (
    {   input_graph_text      => $herschel_graph_text,
        expected_edge_count   => 18,
        expected_vertex_count => 11,
        label                 => 'Herschel Graph',
        preserved             => 1,
    },
    {   input_graph_text      => '0=1,0=2,1=2,1=3,2=3',
        expected_edge_count   => 5,
        expected_vertex_count => 4,
        label                 => 'K4 minus an edge',
        preserved             => 1,
    },
    {   input_graph_text =>
            '0=1,0=4,10=11,10=7,10=9,11=7,1=2,1=4,2=3,2=5,3=5,4=6,5=7,6=8,6=9,8=9',
        expected_edge_count   => 16,
        expected_vertex_count => 12,
        label                 => 'a 12 vertex, 16 edge, Hamiltonian graph',
        preserved             => 1,
    },
    {   input_graph_text      => '0=1,0=2,0=6,1=3,1=7,2=3,2=4,3=5,4=5,5=7',
        expected_edge_count   => 10,
        expected_vertex_count => 8,
        label                 => 'Cube Graph minus 2 edges',
        preserved             => 1,
    },
    {   input_graph_text      => '0=1,0=6,2=4,3=4,3=5',
        expected_edge_count   => 5,
        expected_vertex_count => 7,
        label                 => 'non-contiguous vertex labels',
        preserved             => 1,
    },

    {   input_graph_text      => '0=0,0=1,0=6,2=4,3=4,3=5',
        expected_edge_count   => 5,
        expected_vertex_count => 7,
        label                 => 'graph with self-edge',
        preserved             => 0,
    },
    {   input_graph_text      => '0=1,0=6,2=4,3=4,3=5,3=5',
        expected_edge_count   => 5,
        expected_vertex_count => 7,
        label                 => 'graph with repeated edge',
        preserved             => 0,
    },
    {   input_graph_text      => '0=1,0=6,2=4,3=4,3=5,99',
        expected_edge_count   => 5,
        expected_vertex_count => 8,
        label                 => 'graph with an isolated vertex',
        preserved             => 1,
    },
);

foreach my $test (@tests) {
    my $g = string_to_graph( $test->{input_graph_text} );

    is( scalar( $g->vertices() ),
        $test->{expected_vertex_count},
        "Preserved number of vertices. [$test->{label}]"
    );
    is( scalar( $g->edges() ),
        $test->{expected_edge_count},
        "Preserved number of edges. [$test->{label}]"
    );
    if ( $test->{preserved} ) {
        is( "$g", $test->{input_graph_text},
            "Graph to string is the same as string to graph. [$test->{label}]"
        );
    } else {
        isnt( "$g", $test->{input_graph_text},
            "Graph to string is NOT the same as string to graph. [$test->{label}]"
        );
    }
}

