use strict;
use warnings;
use Test::More tests => 10;

use Graph;
use Graph::Maker;
use Graph::Maker::Degree;
use Math::Random;

require 't/matches.pl';

my $g;

my (@a, @b);

random_set_seed_from_phrase("asdf1511101.10.12.");

# undirected
@a = (2,3,1,1,1);
$g = new Graph::Maker('degree', seq => [@a], strict => 1, undirected => 1);
ok(&checkgraph());

@a = (3,3,3,3,3,3,3,3,3,3,3,3);
$g = new Graph::Maker('degree', seq => [@a], strict => 1, undirected => 1);
ok(&checkgraph());

@a = (5,3,3,3,3,2,2,2,1,1,1);
$g = new Graph::Maker('degree', seq => [@a], strict => 1, undirected => 1);
ok(&checkgraph());

eval {
	@a = (2,2);
	$g = new Graph::Maker('degree', N => 5, seq => [@a], undirected => 1);
};
ok($@);

# directed
@a = (2,3,1,1,1);
$g = new Graph::Maker('degree', seq => [@a], strict => 1);
ok(&checkgraph());
ok(directedok($g));

@a = (3,3,3,3,3,3,3,3,3,3,3,3);
$g = new Graph::Maker('degree', seq => [@a], strict => 1);
ok(&checkgraph());
ok(directedok($g));

@a = (5,3,3,3,3,2,2,2,1,1,1);
$g = new Graph::Maker('degree', seq => [@a], strict => 1);
ok(&checkgraph());
ok(directedok($g));

sub checkgraph
{
	#print "\t$g\n";
	my $r = 1;
	for my $i(0..@a-1)
	{
		$r &&= $a[$i] == $g->in_degree($i+1);
		#print "\t$a[$i] == " . $g->in_degree($i+1) . " $i\n" unless $a[$i] == $g->in_degree($i+1);
	}
	return $r;
}
