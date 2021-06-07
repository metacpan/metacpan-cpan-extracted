#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity::Transforms
    qw(&string_to_graph &add_random_edges);

use Test::More;

plan tests => 6;

$ENV{HC_OUTPUT_FORMAT} = 'none';

while ( defined( my $line = <DATA> ) ) {
    next if $line =~ /^\s*#/;    ### skip comments
    chomp $line;

    if ( $line =~ /^\d+=\d+(,\d+=\d+)*$/ ) {
        my $g = string_to_graph($line);

        my $e         = scalar( $g->edges() );
        my @vertices  = $g->vertices;
        my $v         = @vertices;
        my $max_edges = ( $v * $v - $v ) / 2;

        my $edges_to_add = int( rand( $max_edges - $e ) );

        my $g1 = add_random_edges( $g, $edges_to_add );

        is( scalar( $g1->edges() ),
            $e + $edges_to_add,
            "Succesfully added $edges_to_add edges."
        );
    }
}

1;

__DATA__
###
### This is where test cases for the subroutine Graph::Undirected::Hamiltonicity::Transforms::add_random_edges()
### are written, one per line,
###
### Note: Every time you add a test case, remember to update the "plan tests => NUMBER";

# Here are some test cases:

0=1,0=2,1=2

0=1,0=2,1=2,3=4,3=5,4=5

0=11,0=6,10=12,10=2,11=13,11=14,11=15,11=9,12=14,12=16,12=19,13=16,13=18,14=5,14=6,15=16,15=2,16=4,16=5,17=18,17=5,17=9,19=2,19=7,1=4,1=8,2=3,3=4,3=5,7=8

0=13,0=5,0=8,10=12,10=3,10=5,11=13,11=14,12=2,13=6,13=7,14=4,15=3,15=9,1=2,1=8,2=5,2=6,4=7,4=8,5=8,6=9

0=1,0=10,0=3,0=9,10=2,10=8,1=2,1=4,2=5,3=4,3=6,4=5,4=7,5=8,6=7,6=9,7=8,8=9

0=14,0=26,0=3,0=8,10=17,10=19,10=27,11=19,11=22,11=3,11=5,11=7,11=9,12=2,12=6,13=15,13=7,14=21,15=22,15=25,16=20,16=24,16=28,17=24,17=26,17=9,18=28,18=6,19=27,1=17,1=25,20=25,20=3,21=28,21=6,22=25,22=26,23=4,23=5,24=8,26=29,26=8,27=28,27=7,29=3,2=23,2=27,2=7,3=4,4=5

