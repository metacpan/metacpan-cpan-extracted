use strict;
use warnings;
use Test::More tests => 3;

use Graph;
use Graph::Maker;
use Graph::Maker::SmallWorldWS;

require 't/matches.pl';

my $g;

$g = new Graph::Maker('small_world_ws', N => 100, K => 4, PR => 0.05, undirected => 1);
ok(1); #nothing I can do here for testing...

$g = new Graph::Maker('small_world_ws', N => 100, K => 2, PR => .5, keep_edges => 1, undirected => 1);
ok(not grep {$g->degree($_) < 2} $g->vertices());

$g = new Graph::Maker('small_world_ws', N => 100, K => 2, PR => .5, keep_edges => 1);
ok(directedok($g));
