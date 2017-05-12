# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# check basic add_vertex/add_edge in Graph::ModularDecomposition context
# check check_transitive
# check restriction
# check factor

use Test;
BEGIN { plan tests => 12 };

use Graph::ModularDecomposition;


#########################

sub test3 {
    my $g;
    my $c = 0;
    my %t = (
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df, cg, ch, dg, dh, ag, ah, bg, bh'
	=> 'a-c,a-d,a-g,a-h,b-d,b-g,b-h,c-e,c-f,c-g,c-h,d-e,d-f,d-g,d-h,e-g,e-h,f-h',
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df, cg, ch, dg, dh, ag, ah, bg, bh, ae, af, be, bf'
	=> 'a-c,a-d,a-e,a-f,a-g,a-h,b-d,b-e,b-f,b-g,b-h,c-e,c-f,c-g,c-h,d-e,d-f,d-g,d-h,e-g,e-h,f-h',
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df'
	=> 'a-c,a-d,b-d,c-e,c-f,d-e,d-f,e-g,e-h,f-h'
    );
    while ( my ($pairs, $r) = each %t ) {
	eval {
	    open(STDERR, ">/dev/null") if -w '/dev/null';
	    Graph::ModularDecomposition->debug(3) unless $c;
	    ok( Graph::ModularDecomposition->pairstring_to_graph( $pairs ),
		$r );
	    Graph::ModularDecomposition->debug(0) unless $c++;
	}
    }
}

sub test3a {
    my $g;
    my $c = 0;
    my %t = (
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df, cg, ch, dg, dh, ag, ah, bg, bh'
	=> '',
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df, cg, ch, dg, dh, ag, ah, bg, bh, ae, af, be, bf'
	=> 1,
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df'
	=> ''
    );
    while ( my ($pairs, $r) = each %t ) {
	Graph::ModularDecomposition->debug(3) unless $c;
	ok( Graph::ModularDecomposition->pairstring_to_graph( $pairs )
	    ->check_transitive, $r );
	Graph::ModularDecomposition->debug(0) unless $c++;
    }
}

sub test3b {
    my $g;
    my $c = 0;
    my %t = (
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df, cg, ch, dg, dh, ag, ah, bg, bh'
	=> 'a-c,a-d,b-d',
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df, cg, ch, dg, dh, ag, ah, bg, bh, ae, af, be, bf'
	=> 'a-c,a-d,b-d',
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df'
	=> 'a-c,a-d,b-d'
    );
    while ( my ($pairs, $r) = each %t ) {
	Graph::ModularDecomposition->debug(3) unless $c;
	ok( Graph::ModularDecomposition->pairstring_to_graph( $pairs )
	    ->restriction( split //, 'abcd' ), $r );
	Graph::ModularDecomposition->debug(0) unless $c++;
    }
}

sub test3c {
    my $g;
    my $c = 0;
    my %t = (
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df, cg, ch, dg, dh, ag, ah, bg, bh'
	=> 'ab-cdef,ab-gh,cdef-gh',
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df, cg, ch, dg, dh, ag, ah, bg, bh, ae, af, be, bf'
	=> 'ab-cdef,ab-gh,cdef-gh',
    'ac, ad, bd, eg, eh, fh, ce, cf, de, df'
	=> 'ab-cdef,gh'
    );
    while ( my ($pairs, $r) = each %t ) {
	Graph::ModularDecomposition->debug(3) unless $c;
	my $res = Graph::ModularDecomposition->pairstring_to_graph( $pairs )
	    ->factor( [ ['a','b'], ['c','d','e','f'], ['g','h'] ] );
	$res =~ s/\|//g; # 0.13 introduced VSEP
	ok( $res, $r );
	Graph::ModularDecomposition->debug(0) unless $c++;
    }
}


test3;
test3a;
test3b;
test3c;

