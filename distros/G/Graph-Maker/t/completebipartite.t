use strict;
use warnings;
use Test::More tests => 3;

use Graph;
use Graph::Maker;
use Graph::Maker::CompleteBipartite;
use Math::Random;

require 't/matches.pl';

my $g;


#random_set_seed_from_phrase("asdf1511101.10.12.");

# undirected
$g = new Graph::Maker('complete_bipartite', N1 => 4, N2 => 3, undirected => 1);
ok(matches($g, "1-5,1-6,1-7,2-5,2-6,2-7,3-5,3-6,3-7,4-5,4-6,4-7", 0));

# directed
$g = new Graph::Maker('complete_bipartite', N1 => 4, N2 => 3);
ok(matches($g, "1-5,1-6,1-7,2-5,2-6,2-7,3-5,3-6,3-7,4-5,4-6,4-7", 1));
ok(directedok($g));
