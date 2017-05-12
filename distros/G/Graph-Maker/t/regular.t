use strict;
use warnings;
use Test::More tests => 5;

use Graph;
use Graph::Maker;
use Graph::Maker::Regular;

require 't/matches.pl';

my $g;

# directed
eval {
	$g = new Graph::Maker('regular', N => 6, K => 3);
};
ok($@ || 0 == grep {$g->in_degree($_) != 3} $g->vertices());
ok($@ || directedok($g));

# undirected
eval {
	$g = new Graph::Maker('regular', N => 6, K => 3, undirected => 1);
};
ok($@ || 0 == grep {$g->in_degree($_) != 3} $g->vertices());

eval {
	$g = new Graph::Maker('regular', N => 5, K => 2, undirected => 1);
};
ok($@ || 0 == grep {$g->in_degree($_) != 2} $g->vertices());

# multiedged
eval {
	$g = new Graph::Maker('regular', N => 4, K => 2, multiedged => 1);
};
ok($@ || 0 == grep {$g->in_degree($_) != 2} $g->vertices());
