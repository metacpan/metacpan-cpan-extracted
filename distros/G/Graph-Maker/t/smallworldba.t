use strict;
use warnings;
use Test::More tests => 4;

use Graph;
use Graph::Maker;
use Graph::Maker::SmallWorldBA;

require 't/matches.pl';

my $g;

$g = new Graph::Maker('small_world_ba', N => 50, M => 2, undirected => 1);
ok(not grep {$g->degree($_) < 1} $g->vertices());

$g = new Graph::Maker('small_world_ba', N => 50, M => 2, undirected => 1);
ok(not grep {$g->degree($_) < 1} $g->vertices());

$g = new Graph::Maker('small_world_ba', N => 50, M => 2);
ok(not grep {$g->in_degree($_) < 1} $g->vertices());
ok(directedok($g));
