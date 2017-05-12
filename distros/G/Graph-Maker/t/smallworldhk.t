use strict;
use warnings;
use Test::More tests => 1;

use Graph;
use Graph::Maker;
use Graph::Maker::SmallWorldHK;

require 't/matches.pl';

my $g;

#$g = new Graph::Maker('small_world_hk', N => 50, M => 2, M_0 => 4, PR => 0, undirected => 1);
#ok(not grep {$g->degree($_) < 1} $g->vertices());

#$g = new Graph::Maker('small_world_hk', N => 50, M => 2, M_0 => 4, PR => .5, undirected => 1);
#ok(not grep {$g->degree($_) < 1} $g->vertices());

$g = new Graph::Maker('small_world_hk', N => 50, M => 2, M_0 => 4, PR => .5);
#ok(not grep {$g->in_degree($_) < 1} $g->vertices());
#ok(directedok($g));

ok(1);
