#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity::Transforms
    qw(&string_to_graph &swap_vertices);

use Test::More;

plan tests => 8;

my $herschel_graph_text =
    '0=1,0=10,0=3,0=9,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9';

my @tests = (
    {   input_graph_text => $herschel_graph_text,
        vertices_to_swap => [ 0, 1 ],
        expected_output_graph_text =>
            '0=1,0=2,0=4,10=6,10=8,1=10,1=3,1=9,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9'
    },
    {   input_graph_text           => '0=1,0=2,1=2,1=3,2=3',
        vertices_to_swap           => [ 0, 1 ],
        expected_output_graph_text => '0=1,0=2,0=3,1=2,2=3'
    },
    {   input_graph_text =>
            '0=1,0=4,10=11,10=7,10=9,11=7,1=2,1=4,2=3,2=5,3=5,4=6,5=7,6=8,6=9,8=9',
        vertices_to_swap => [ 0, 1 ],
        expected_output_graph_text =>
            '0=1,0=2,0=4,10=11,10=7,10=9,11=7,1=4,2=3,2=5,3=5,4=6,5=7,6=8,6=9,8=9'
    },
    {   input_graph_text           => '0=1,0=2,1=2,1=3,2=3',
        vertices_to_swap           => [ 0, 1 ],
        expected_output_graph_text => '0=1,0=2,0=3,1=2,2=3'
    },

);

foreach my $test (@tests) {
    my $input_graph = string_to_graph( $test->{input_graph_text} );

    my $output_graph =
        swap_vertices( $input_graph, @{ $test->{vertices_to_swap} } );
    is( "$output_graph",
        $test->{expected_output_graph_text},
        "graph changed as expected."
    );

    my $output_graph2 =
        swap_vertices( $output_graph, @{ $test->{vertices_to_swap} } );
    is( "$output_graph2", $test->{input_graph_text},
        "Two consecutive swaps of the same vertices leave the graph unchanged."
    );

}

