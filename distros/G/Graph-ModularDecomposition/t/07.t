# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# test showing that Graph::add_edge is now idempotent
# earlier versions of Graph were not

use Test;
BEGIN { plan tests => 1 };
use Graph::ModularDecomposition;

#########################

sub test7 {
    print "test7\n";
    my $g = new Graph::ModularDecomposition;
    $g->add_edges( qw( a b b c a b ) );
    if ( $Graph::VERSION > 0.20105 ) {
	ok $g, 'a-b,b-c';
    } else {
	ok $g, 'a-b,a-b,b-c';
    }
}


test7;
