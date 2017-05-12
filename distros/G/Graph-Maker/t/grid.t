use strict;
use warnings;
use Test::More tests => 7;

use Graph;
use Graph::Maker;
use Graph::Maker::Grid;

require 't/matches.pl';

my $g;

# directed
$g = new Graph::Maker('grid', dims => [3,3]);
ok(matches($g, "1-2,2-3,4-1,4-5,4-7,5-2,5-6,5-8,6-3,6-9,7-8,8-9", 1));
ok(directedok($g));

$g = new Graph::Maker('grid', dims => [3,3], cyclic => 1);
ok(matches($g, "1-2,2-3,4-1,4-5,4-7,5-2,5-6,5-8,6-3,6-9,7-8,8-9,7-9,9-3,8-2,7-1,4-6,1-3", 1));
ok(directedok($g));

# undirected
$g = new Graph::Maker('grid', dims => [3,3], undirected => 1);
ok(matches($g, "1-2,2-3,4-1,4-5,4-7,5-2,5-6,5-8,6-3,6-9,7-8,8-9", 0));

$g = new Graph::Maker('grid', dims => [3,3], cyclic => 1, undirected => 1);
ok(matches($g, "1-2,2-3,4-1,4-5,4-7,5-2,5-6,5-8,6-3,6-9,7-8,8-9,7-9,9-3,8-2,7-1,4-6,1-3", 0));

$g = new Graph::Maker('grid', dims => [4,3], undirected => 1);
ok(matches($g, "10-11,10-7,11-12,11-8,12-9,1-2,1-4,2-3,2-5,3-6,4-5,4-7,5-6,5-8,6-9,7-8,8-9", 0));
