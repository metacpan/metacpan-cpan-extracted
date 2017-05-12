use strict;
use warnings;
use Test::More tests => 3;

use Graph;
use Graph::Maker;
use Graph::Maker::Hypercube;

require 't/matches.pl';

my $g;

# directed
$g = new Graph::Maker('hypercube', N => 4);
ok(matches($g, "10-12,10-14,10-2,10-9,11-12,11-15,11-3,11-9,12-16,12-4,13-14,13-15,13-5,13-9,14-16,14-6,15-16,15-7,16-8,1-2,1-3,1-5,1-9,2-4,2-6,3-4,3-7,4-8,5-6,5-7,6-8,7-8", 1));
ok(directedok($g));

# undirected
$g = new Graph::Maker('hypercube', N => 4, undirected => 1);
ok(matches($g, "10-12,10-14,10-2,10-9,11-12,11-15,11-3,11-9,12-16,12-4,13-14,13-15,13-5,13-9,14-16,14-6,15-16,15-7,16-8,1-2,1-3,1-5,1-9,2-4,2-6,3-4,3-7,4-8,5-6,5-7,6-8,7-8", 0));
