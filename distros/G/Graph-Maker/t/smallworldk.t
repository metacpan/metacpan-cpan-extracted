use strict;
use warnings;
use Test::More tests => 7;

use Graph;
use Graph::Maker;
use Graph::Maker::SmallWorldK;

require 't/matches.pl';

my $g;

$g = new Graph::Maker('small_world_k', N => 4, Q => 0, cyclic => 1, undirected => 1);
ok($g->successors(4) == 4 && $g->successors(1) == 4);

$g = new Graph::Maker('small_world_k', N => 4, P => 2, Q => 0, cyclic => 1, undirected => 1);
ok($g->successors(4) == 10 && $g->successors(1) == 10);

$g = new Graph::Maker('small_world_k', N => 4, undirected => 1);
ok($g->successors(4) == 2 && $g->successors(1) == 2);

$g = new Graph::Maker('small_world_k', N => 4, P => 2, Q => 0, undirected => 1);
ok($g->successors(4) == 5 && $g->successors(1) == 5);

$g = new Graph::Maker('small_world_k', N => 4, P => 2, Q => 1, undirected => 1);
ok($g->successors(4) >= 5 && $g->successors(1) >= 5);

$g = new Graph::Maker('small_world_k', N => 4, P => 2, Q => 1);
ok($g->successors(4) >= 5 && $g->successors(1) >= 5);
ok(directedok($g));

#use Graph::Writer::GML;
#Graph::Writer::GML->new->write_graph($g, 'test.gml');

