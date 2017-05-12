# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# more tests of classify()

use Test;
BEGIN { plan tests => 8 };
use Graph::ModularDecomposition;

#########################

my $g = new Graph::ModularDecomposition;
ok ref( $g ), 'Graph::ModularDecomposition';
$g->add_vertex( 'a' );
ok ref( $g ), 'Graph::ModularDecomposition';
ok $g->classify, 's';

$g->add_edge( 'a', 'c' );
ok ref( $g ), 'Graph::ModularDecomposition';
ok $g->classify, 's';

$g->add_edge( 'a', 'd' );
ok ref( $g ), 'Graph::ModularDecomposition';
$g->add_edge( 'b', 'd' );
ok ref( $g ), 'Graph::ModularDecomposition';
ok $g->classify, 'i';
