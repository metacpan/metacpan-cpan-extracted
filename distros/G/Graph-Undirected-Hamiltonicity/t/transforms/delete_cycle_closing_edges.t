#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity::Transforms
    qw(
       &get_required_graph
       &delete_cycle_closing_edges
       &string_to_graph
    );

use Test::More;

plan tests => 4;

my $herschel_graph_text =
    '0=1,0=10,0=3,0=9,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9';

my @tests = (
    {   input_graph_text           => $herschel_graph_text,
        expected_deleted_edges     => 0,
        expected_output_graph_text => undef,
    },
    {   input_graph_text           => '0=1,0=3,1=2,2=3,2=8,3=4,3=5,3=7,4=6,4=7,4=8,5=6,5=7,6=7,6=8',
        expected_deleted_edges     => 1,
        expected_output_graph_text => '0=1,0=3,1=2,2=8,3=4,3=5,3=7,4=6,4=7,4=8,5=6,5=7,6=7,6=8' ## delete 2=3
    },

    {   input_graph_text           => '0=11,0=6,10=12,10=2,11=13,11=14,11=15,11=9,12=14,12=16,12=19,13=16,13=18,14=5,14=6,15=16,15=2,16=4,16=5,17=18,17=5,17=9,19=2,19=7,1=4,1=8,2=3,3=4,3=5,7=8',
        expected_deleted_edges     => 0,
        expected_output_graph_text => undef,
    },
);

foreach my $test (@tests) {
    my $g = string_to_graph( $test->{input_graph_text} );

    my ( $required_graph, $g1 ) = get_required_graph($g);

    my ( $deleted_edges, $output_graph ) = delete_cycle_closing_edges($g, $required_graph);

    is( $deleted_edges,
        $test->{expected_deleted_edges},
        "Deleted the expected number of cycle closing edges."
    );

    if ( $deleted_edges ) {
        is( "$output_graph",
            $test->{expected_output_graph_text},
            "Deleted all the cycle closing edges expected."
            );
    }

}

