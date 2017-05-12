# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# check TransitiveClosure_Floyd_Warshall in ModularDecomposition context
# check instance method invocation style of pairstring_to_graph

use Test;
BEGIN { plan tests => 15 };
use Graph::ModularDecomposition;


#########################

sub test14 {
    my %t = (
	'a' => 's',
	'a-c,b,a-d,b-d' => 'i', # redundant b vertex
	'a-b,b-c,c' => 'n', # repeated vertex
	'a-b,a-c,b-c,a-c' => 's', # repeated edge
	'a-b,c-b,d-b,d-c' => 's'
    );
    my %c;
    while ( my ($p, $r) = each %t ) {
	my $g = Graph::ModularDecomposition->pairstring_to_graph( $p );
	my $h = $g->TransitiveClosure_Floyd_Warshall;
	foreach ( $h->vertices ) { $h->delete_edge( $_, $_ ) }

	ok $g->classify, $r;
	ok $h->classify ne 'n';
	ok $g->pairstring_to_graph( $p )->TransitiveClosure_Floyd_Warshall
	    ->classify, $h->classify;
    }
}


test14;
