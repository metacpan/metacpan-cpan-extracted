# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# check bitvector2 conversion, if available

use Test;
BEGIN { plan tests => 3 };
use Graph::ModularDecomposition;

my $skip;
BEGIN {
    $skip = 1;
    eval {require Graph::Bitvector2; 1} and $skip = 0;
}

#########################

my $g = new Graph::ModularDecomposition;
#print STDERR "skip status: $skip\n";
$g->add_edge( 'a', 'c' );
$g->add_edge( 'a', 'd' );
$g->add_edge( 'b', 'd' );

eval {
    open(STDERR, ">/dev/null") if -w '/dev/null';
    Graph::ModularDecomposition->debug(3);
    skip $skip, eval { $g->to_bitvector2 . '' }, '011010';
    Graph::ModularDecomposition->debug(0);
};
skip $skip, eval { $g->to_bitvector2 . '' }, '011010';

$g->add_edge( 'c', 'b' );
skip $skip, eval { $g->to_bitvector2 . '' }, '011210';

