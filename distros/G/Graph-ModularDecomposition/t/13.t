# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# check classify in ModularDecomposition context

use Test;
BEGIN { plan tests => 7 };

use Graph::ModularDecomposition;

#########################

sub test13 {
    my %t = (
	'a-b,c-b,d-b,d-c' => 's',
	'a-b,c-b,d-b,d-c,d-a,b-e,a-e,c-e,d-e,f-g,f-e,g-e' => 's',
	'a-b,a-c,b-c' => 's',
	'a-c,a-d,b-d' => 'i',
	'a-b,b-c' => 'n',
    );
    my %c;
    while ( my ($p, $r) = each %t ) {
	my $g = Graph::ModularDecomposition->pairstring_to_graph( $p );
	$c{ $p } = $g->classify;
	ok $c{$p}, $r;
    }
    # now check some of the code with debugging on
    my $g = Graph::ModularDecomposition->pairstring_to_graph( 'ab,ac,bc,b,ac' );
    eval {
	open(STDERR, ">/dev/null") if -w '/dev/null';
	$g->debug(1);
	ok $g->classify, 's';

	$g = new Graph::ModularDecomposition;
	ok $g->classify, 's';
	$g->debug(0);
    };
}


test13;
