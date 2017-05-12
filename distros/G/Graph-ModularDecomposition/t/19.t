# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# testing delete of vertex when loop is present
# broke in Graph-20041016

use Test;
BEGIN { plan tests => 2 };
use Graph::Directed;

my $f = new Graph::Directed;
$f->add_edges( qw( a a a b ) );
ok $f, 'a-a,a-b';
ok $f->delete_vertex('a'), 'b';

