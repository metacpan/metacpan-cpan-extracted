#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 9;

use Graph::Fast;

my $g = Graph::Fast->new();

# if there's one possible path then that one should obviously be returned.
$g->add_edge("A", "B", 5);
is_deeply([$g->dijkstra("A", "B")], [{ from => "A", to => "B", weight => 5 }], "only one possible path returned");

# add a third, unrelated vertex. the path should not change.
$g->add_edge("A", "C", 1);
is_deeply([$g->dijkstra("A", "B")], [{ from => "A", to => "B", weight => 5 }], "correct path returned after adding unrelated vertex");

# add a second path from A to B, using D. this one is longer than the existing
# and shouldn't be used therefore.
$g->add_edge("A", "D", 10);
$g->add_edge("D", "B", 10);
is_deeply([$g->dijkstra("A", "B")], [{ from => "A", to => "B", weight => 5 }], "shorter path returned even if there's a longer one");

# now add a third path over E that is faster.
$g->add_edge("A", "E", 2);
$g->add_edge("E", "B", 2);
is_deeply([$g->dijkstra("A", "B")], [{ from => "A", to => "E", weight => 2 }, { from => "E", to => "B", weight => 2 }], "new shortest path taken");

# how about we go find a way between two nodes that are unreachable, due
# to directionality?
is_deeply([$g->dijkstra("B", "A")], [], "returns empty list when there is no path");

# and between nodes that don't exist?
is_deeply([$g->dijkstra("B", "X")], [], "returns empty list for unknown nodes pt. 1");
is_deeply([$g->dijkstra("X", "B")], [], "returns empty list for unknown nodes pt. 2");

# test usage of a different queue module - here: dummy module that returns nothing
# and will therefore cause failure to find a path
{ package NullQueue; sub insert { } sub update { } sub pop { undef; } sub delete { } }
$g->{_queue_maker} = sub { bless({}, "NullQueue"); };
is_deeply([$g->dijkstra("A", "B")], [], "can use different queue module");

# here: actual module, should return same result now.
SKIP: {
	eval { require List::PriorityQueue };
	skip("List::PriorityQueue not installed, can't test with different queue module", 1) if ($@);

	$g->{_queue_maker} = sub { List::PriorityQueue->new() };
	is_deeply([$g->dijkstra("A", "B")], [{ from => "A", to => "E", weight => 2 }, { from => "E", to => "B", weight => 2 }], "different queue module works");
}
