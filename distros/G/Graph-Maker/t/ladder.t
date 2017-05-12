use strict;
use warnings;
use Test::More tests => 3;

use Graph;
use Graph::Maker;
use Graph::Maker::Ladder;

require 't/matches.pl';

my $g;

# directed
$g = new Graph::Maker('ladder', rungs => 4);
ok(matches($g, "1-2,2-3,3-4,5-6,6-7,7-8,1-5,2-6,3-7,4-8", 1));
ok(directedok($g));

# undirected
$g = new Graph::Maker('ladder', rungs => 4, undirected => 1);
ok(matches($g, "1-2,2-3,3-4,5-6,6-7,7-8,1-5,2-6,3-7,4-8", 0));
