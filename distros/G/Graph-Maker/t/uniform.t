use strict;
use warnings;
use Test::More tests => 6;

use Graph;
use Graph::Maker;
use Graph::Maker::Uniform;
use Math::Random;

require 't/matches.pl';

my $g;

random_set_seed_from_phrase("This is my phrase");

# undirected
$g = new Graph::Maker('uniform', N => 4, radius => .1, undirected => 1);
ok(matches($g, "2-4,1,3", 0));

$g = new Graph::Maker('uniform', N => 4, radius => .2, repel => .05, undirected => 1);
ok(matches($g, "1-2,1-3,1-4,2-3,2-4,3-4", 0));

# directed
$g = new Graph::Maker('uniform', N => 8, radius => .1);
ok(matches($g, "2-7,1,3,4,5,6,8", 1));
ok(directedok($g));

$g = new Graph::Maker('uniform', N => 8, repel => .05, radius => .2);
ok(matches($g, "1-2,1-3,1-4,1-5,1-6,1-7,1-8,2-3,2-4,2-5,2-6,2-7,2-8,3-4,3-5,3-6,3-7,3-8,4-5,4-6,4-7,4-8,5-6,5-7,5-8,6-7,6-8,7-8", 1));
ok(directedok($g));
