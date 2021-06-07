#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity qw(:all);
use Graph::Undirected::Hamiltonicity::Transforms qw(&string_to_graph);
use Graph::Undirected::Hamiltonicity::Wolfram qw(:all);

use Test::More;

$ENV{HC_OUTPUT_FORMAT} = 'none';

my $url = get_url_from_config();
if ($url) {
    plan tests => 28;
} else {
    plan tests => 14;
    print $ENV{HOME} . "/hamilton.ini doesn't exist. ";
    say "Skipping Wolfram verification.";
}

while ( defined( my $line = <DATA> ) ) {
    next if $line =~ /^\s*#/;    ### skip comments
    chomp $line;

    if ( $line =~ /^([^|]+)\|([01])\|(\d+|\d+=\d+(,\d+=\d+)*)$/ ) {
        my ( $label, $expected_result, $graph_text ) = ( $1, $2, $3 );
        my $g = string_to_graph($graph_text);

        my $is_hamiltonian = graph_is_hamiltonian($g);
        is( $is_hamiltonian, $expected_result, $label );

        if ($url) {
            is( is_hamiltonian_per_wolfram($g),
                $expected_result, "Wolfram: $label" );
        }
    }
}

1;

__DATA__
###
### This is where test cases for the subroutine Graph::Undirected::Hamiltonicity::graph_is_hamiltonian()
### are written, one per line,
### in the format: label|expected_result|graph_text
###
###    label: can be any string not containing the pipe ( | ) character.
###
###
###    expected_result: can be 1, or 0.
###                     where
###                           1 means GRAPH_IS_HAMILTONIAN
###                           0 means GRAPH_IS_NOT_HAMILTONIAN
###
###
###    graph_text: is a string representation of the graph.
###
### Note: Every time you add a test case, remember to update the "plan tests => NUMBER";

# Here are some test cases:

a single vertex|1|8

a two vertex graph|0|42=69

a simple 3 vertex, 3 edge graph|1|0=1,0=2,1=2

a simple canonical Hamiltonian cycle|1|0=1,0=5,1=2,2=3,3=4,4=5

a 6 vertex, 6 edge non-connected graph|0|0=1,0=2,1=2,3=4,3=5,4=5

a medium sized hamiltonian graph|1|0=11,0=6,10=12,10=2,11=13,11=14,11=15,11=9,12=14,12=16,12=19,13=16,13=18,14=5,14=6,15=16,15=2,16=4,16=5,17=18,17=5,17=9,19=2,19=7,1=4,1=8,2=3,3=4,3=5,7=8

a non-hamiltonian graph|0|0=13,0=5,0=8,10=12,10=3,10=5,11=13,11=14,12=2,13=6,13=7,14=4,15=3,15=9,1=2,1=8,2=5,2=6,4=7,4=8,5=8,6=9

the Herschel Graph|0|0=1,0=10,0=3,0=9,10=2,10=8,1=2,1=4,2=5,3=4,3=6,4=5,4=7,5=8,6=7,6=9,7=8,8=9

the Herschel Graph with 1 extra edge|1|0=1,0=10,0=3,0=9,10=2,10=8,1=2,1=4,2=5,3=4,3=6,4=5,4=7,5=8,6=7,6=9,7=8,8=9,9=10

a 30 vertex, 50 edge hamiltonian graph|1|0=14,0=26,0=3,0=8,10=17,10=19,10=27,11=19,11=22,11=3,11=5,11=7,11=9,12=2,12=6,13=15,13=7,14=21,15=22,15=25,16=20,16=24,16=28,17=24,17=26,17=9,18=28,18=6,19=27,1=17,1=25,20=25,20=3,21=28,21=6,22=25,22=26,23=4,23=5,24=8,26=29,26=8,27=28,27=7,29=3,2=23,2=27,2=7,3=4,4=5

a 12 vertex hamiltonian graph|1|0=1,0=4,1=2,1=4,2=3,2=5,3=5,4=6,5=7,6=8,6=9,7=10,7=11,8=9,9=10,10=11

Cube Graph|1|0=1,0=2,0=6,1=3,1=7,2=3,2=4,3=5,4=5,4=6,5=7,6=7

Cube Graph minus 2 edges|0|0=1,0=2,0=6,1=3,1=7,2=4,3=5,4=5,4=6,5=7

Petersen graph|0|0=1,0=4,0=5,1=2,1=6,2=3,2=7,3=4,3=8,4=9,5=7,5=8,6=8,6=9,7=9
