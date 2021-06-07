#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity;
use Graph::Undirected::Hamiltonicity::Transforms
    qw(&string_to_graph &get_random_isomorph);

use Test::More;

plan tests => 12;

my @tests = (
    {   label => 'Herschel Graph',
        input_graph_text =>
            '0=1,0=10,0=3,0=9,10=6,10=8,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,7=8,8=9',
        expected_is_hamiltonian => 0,
    },
    {   label            => 'Cube Graph',
        input_graph_text => '0=1,0=2,0=6,1=3,1=7,2=3,2=4,3=5,4=5,4=6,5=7,6=7',
        expected_is_hamiltonian => 1,
    },
    {   label => 'Octagon in Square Graph',
        input_graph_text =>
            '0=1,0=4,1=2,1=4,2=3,2=5,3=5,4=6,5=7,6=8,6=9,7=10,7=11,8=9,9=10,10=11',
        expected_is_hamiltonian => 1,
    },
    {
        label => 'Petersen Graph',
        input_graph_text => '0=1,0=4,0=5,1=2,1=6,2=3,2=7,3=4,3=8,4=9,5=7,5=8,6=8,6=9,7=9',
        expected_is_hamiltonian => 0,
    }
);

foreach my $test (@tests) {

    my $label      = $test->{label};
    my $graph_text = $test->{input_graph_text};

    ### A random isomorph is very likely to be different from the original,
    ### but it's not 100% guaranteed.
    my $before_graph = string_to_graph($graph_text);
    my $after_graph  = get_random_isomorph($before_graph);
    isnt( "$after_graph", "$before_graph",
        "[$label] probably different after get_random_isomorph(). IF THIS TEST FAILS, JUST RE-RUN THE TEST. ODDS ARE, IT WILL PASS."
    );

    ### The distribution of degrees in the graph remains unchanged after get_random_isomorph.
    my %before_degree_hash = get_degree_hash($before_graph);
    my %after_degree_hash  = get_degree_hash($after_graph);
    is_deeply( \%after_degree_hash, \%before_degree_hash,
        "[$label] degree hash unchanged after get_random_isomorph()" );

    ### The Hamiltonicity of the graph remains unchanged after get_random_isomorph
    my $is_hamiltonian = graph_is_hamiltonian($after_graph);
    is( $is_hamiltonian,
        $test->{expected_is_hamiltonian},
        "[$label] Hamiltonicity unchanged after get_random_isomorph()"
    );
}

##########################################################################

sub get_degree_hash {
    my ($g) = @_;

    my %degree_hash;
    foreach my $vertex ( $g->vertices() ) {
        $degree_hash{ $g->degree($vertex) }++;
    }

    return %degree_hash;
}

##########################################################################

1;

