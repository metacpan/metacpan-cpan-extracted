use strict;
use warnings;
use Test::More tests => 11;

use Graph;
use Graph::Maker;
use Graph::Maker::Bipartite;
use Math::Random;

require 't/matches.pl';

my $g;

my (@a, @b);

random_set_seed_from_phrase("asdf1511101.10.12.");

# undirected
@a = (2,3,1,1,1); @b = (2,1,1,3,1);
$g = new Graph::Maker('bipartite', seq1 => [@a], seq2 => [@b], strict => 1, undirected => 1);
ok(&checkgraph());

@a = (2,3,1,1,1); @b = (2,3,1,2);
$g = new Graph::Maker('bipartite', seq1 => [@a], seq2 => [@b], strict => 1, undirected => 1);
ok(&checkgraph());

@a = (2,3,1,2,1); @b = (2,2,1,3,1);
$g = new Graph::Maker('bipartite', seq1 => [@a], seq2 => [@b], strict => 1, undirected => 1);
ok(&checkgraph());

@a = (2); @b = (2);
eval {
	$g = new Graph::Maker('bipartite', N1 => 5, N2 => 4, seq1 => [@a], seq2 => [@b], strict => 1);
};
ok($@ && not &checkgraph());

# directed
@a = (2,3,1,1,1); @b = (2,1,1,3,1);
$g = new Graph::Maker('bipartite', seq1 => [@a], seq2 => [@b], strict => 1);
ok(&checkgraph());
ok(directedok($g));

@a = (2,3,1,1,1); @b = (2,3,1,2);
$g = new Graph::Maker('bipartite', seq1 => [@a], seq2 => [@b], strict => 1);
ok(&checkgraph());
ok(directedok($g));

@a = (2,3,1,2,1); @b = (2,2,1,3,1);
$g = new Graph::Maker('bipartite', seq1 => [@a], seq2 => [@b], strict => 1);
ok(&checkgraph());
ok(directedok($g));

@a = (2); @b = (2);
eval {
	$g = new Graph::Maker('bipartite', N1 => 5, N2 => 4, seq1 => [@a], seq2 => [@b], strict => 1);
};
ok($@ && not &checkgraph());

sub checkgraph
{
	#print "\t$g\n";
	my $r = 1;
	for my $i(0..@a-1)
	{
		$r &&= $a[$i] == $g->in_degree($i+1);
		#print "\t$a[$i] == " . $g->in_degree($i+1) . " $i\n" unless $a[$i] == $g->in_degree($i+1);
	}
	for my $i(0..@b-1)
	{
		$r &&= $b[$i] == $g->in_degree(@a+1+$i);
		#print "\t$b[$i] == " . $g->in_degree(@a+1+$i) . " " . (@b+1+$i) . "\n" unless $b[$i] == $g->in_degree(@a+1+$i);
	}
	return $r;
}
