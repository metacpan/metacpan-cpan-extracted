# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# more tests of classify()

use Test;
BEGIN { plan tests => 6 };
use Graph::ModularDecomposition;

#########################

my $g = new Graph::ModularDecomposition;
$g->add_vertex( 'a' );
ok $g->classify, 's';

$g->add_vertex( 'b' );
ok $g->classify, 's';

$g->add_edges( qw(a c a d b d) );
ok $g->classify, 'i';

$g->add_vertex( 'e' );
ok $g->classify, 'd';

$g->add_edge( 'e', 'b' );
ok $g->classify, 'n';

$g->add_edges( qw(e g f g e d f d g d) );
ok $g->classify, 'p';

