#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity::Transforms
    qw(&string_to_graph &delete_non_required_neighbors);

use Test::More;

plan tests => 10;

my $herschel_graph_text =
    '0=1,0=3,0=9,0=10,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,6=10,7=8,8=9,8=10';

my @tests = (
    {   input_graph_text          => $herschel_graph_text,
        input_required_graph_text => '0=1,0=3',
        expected_deleted_edges    => 2,
        expected_output_graph_text =>
            '0=1,0=3,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9'
    },
    {   input_graph_text          => $herschel_graph_text,
        input_required_graph_text => '0=1,0=3,8=9,8=10',
        expected_deleted_edges    => 4,
        expected_output_graph_text =>
            '0=1,0=3,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,6=7,8=9'
    },
    {   input_graph_text          => $herschel_graph_text,
        input_required_graph_text => '0=1,0=3,3=4,4=5,8=9,8=10',
        expected_deleted_edges    => 7,
        expected_output_graph_text =>
            '0=1,0=3,10=6,10=8,1=2,2=5,2=9,3=4,4=5,6=7,8=9'
    },
    {   input_graph_text          => $herschel_graph_text,
        input_required_graph_text => '0=1,0=3,2=5,2=9,3=4,4=5,8=9,8=10',
        expected_deleted_edges    => 8,
        expected_output_graph_text =>
            '0=1,0=3,10=6,10=8,2=5,2=9,3=4,4=5,6=7,8=9'
    },
    {   input_graph_text => $herschel_graph_text,
        input_required_graph_text =>
            '0=1,0=3,10=6,2=5,2=9,3=4,4=5,6=7,8=9,8=10',
        expected_deleted_edges => 8,
        expected_output_graph_text =>
            '0=1,0=3,10=6,10=8,2=5,2=9,3=4,4=5,6=7,8=9'
    },

);

foreach my $test (@tests) {
    my $required_graph =
        string_to_graph( $test->{input_required_graph_text} );

    my $g = string_to_graph( $test->{input_graph_text} );
    foreach my $edge_ref ( $required_graph->edges() ) {
        $g->set_edge_attribute( @$edge_ref, 'required', 1 );
    }

    my ( $deleted_edges, $output_graph ) =
        delete_non_required_neighbors( $g, $required_graph );

    is( $deleted_edges,
        $test->{expected_deleted_edges},
        "Deleted the expected number of edges."
    );

    if ( $deleted_edges ) {
        is( "$output_graph",
            $test->{expected_output_graph_text},
            "Deleted all the edges expected."
            );
    }

}

