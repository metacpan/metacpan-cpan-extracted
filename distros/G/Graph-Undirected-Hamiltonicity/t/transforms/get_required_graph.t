#!perl

use Modern::Perl;

use Test::More;
plan tests => 77;

use Graph::Undirected::Hamiltonicity::Transforms
    qw(&string_to_graph &get_required_graph);

my $herschel_graph_text =
    '0=1,0=10,0=3,0=9,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9';

my @tests = (
    {   input_graph_text             => $herschel_graph_text,
        expected_required_graph_text => '0,1,10,2,3,4,5,6,7,8,9',
    },
    {   input_graph_text             => '0=1,0=2,1=2,1=3,2=3',
        expected_required_graph_text => '0=1,0=2,1=3,2=3',
    },
    {   input_graph_text =>
            '0=1,0=4,1=2,1=4,2=3,2=5,3=5,4=6,5=7,6=8,6=9,7=10,7=11,8=9,9=10,10=11',
        expected_required_graph_text => '0=1,0=4,10=11,11=7,2=3,3=5,6=8,8=9',
    },

    {   input_graph_text           => '0=1,0=3,1=2,2=3,2=8,3=4,3=5,3=7,4=6,4=7,4=8,5=6,5=7,6=7,6=8',
        expected_required_graph_text => '0=1,0=3,1=2,4,5,6,7,8'
    },
);

foreach my $test (@tests) {
    my $g = string_to_graph( $test->{input_graph_text} );

    my ( $required_graph, $output_graph ) = get_required_graph($g);

    is( "$required_graph",
        $test->{expected_required_graph_text},
        "Got the expected required graph."
    );

    foreach my $edge_ref ( $required_graph->edges() ) {
        is( $output_graph->get_edge_attribute( @$edge_ref, 'required' ),
            1, "the edge has been marked required." );
        $output_graph->set_edge_attribute( @$edge_ref, 'required', 0 );
    }

    foreach my $edge_ref ( $output_graph->edges() ) {
        isnt( $output_graph->get_edge_attribute( @$edge_ref, 'required' ),
            1, "only edges in the required graph can be marked required." );
    }

    is( "$output_graph", "$g",
        "the graph is intact, except for attributes." );

}

