use strict;
use warnings;
use Test::More tests => 6;

use Graph;
use Graph::Maker;
use Graph::Maker::Random;

require 't/matches.pl';

my $g;

# directed
$g = new Graph::Maker('random', N => 100, M => 75);
ok($g->is_directed() && $g->vertices() == 100 && $g->edges() == 150);
ok(directedok($g));

$g = new Graph::Maker('random', N => 100, PR => .1);
ok($g->is_directed() && $g->vertices() == 100);

#print "$g\n";

ok(directedok($g));

# undirected
$g = new Graph::Maker('random', N => 100, M => 75, undirected => 1);
ok($g->is_undirected() && $g->vertices() == 100 && $g->edges() == 75);

$g = new Graph::Maker('random', N => 100, PR => .1, undirected => 1);
ok($g->is_undirected() && $g->vertices() == 100);
