# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# check strongly_connected_graph in Graph::ModularDecomposition context

use Test;
BEGIN { plan tests => 6 };
use Graph::ModularDecomposition;

#########################

sub test6 {
    my %t = (
	'a' => 'a',
	'a,b,c' => 'a,b,c',
	'a-b,b-a' => 'a+b',
	'jk-rq,rq-a,a-jk' => 'a+jk+rq',
	'b-c,b-f,b-gh,b-ijkl,c-de,de-gh,de-ijkl,f-de,f-gh,gh-f'
	    => 'b-c,b-de+f+gh,b-ijkl,c-de+f+gh,de+f+gh-ijkl',
	'b-c,b-f,b-a,b-d,c-e,e-a,e-d,f-e,f-a,a-f'
	    => 'a+e+f-d,b-a+e+f,b-c,b-d,c-a+e+f'
    );
    my $g;
    while ( my ($pairs, $r) = each %t ) {
	$g = new Graph::ModularDecomposition;
	foreach ( split /,/, $pairs ) {
	    if ( /-/ ) { $g->add_edge(split /-/) }
	    else { $g->add_vertex( $_ ) }
	}
	ok $g = $g->strongly_connected_graph, $r;
    }
}


test6;
