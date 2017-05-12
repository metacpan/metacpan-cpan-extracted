use strict;
use warnings;
use Test::More tests => 3;

use Graph;
use Graph::Maker;
use Graph::Maker::Linear;

require 't/matches.pl';

my $g;

# directed
$g = new Graph::Maker('linear', N => 10);
ok(matches($g, "1-2,2-3,3-4,4-5,5-6,6-7,7-8,8-9,9-10", 1));
ok(directedok($g));

# undirected
$g = new Graph::Maker('linear', N => 10, undirected => 1);
ok(matches($g, "1-2,2-3,3-4,4-5,5-6,6-7,7-8,8-9,9-10", 0));
