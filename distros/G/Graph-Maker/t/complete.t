use strict;
use warnings;
use Test::More tests => 3;

use Graph;
use Graph::Maker;
use Graph::Maker::Complete;

require 't/matches.pl';

my $g;

# directed
$g = new Graph::Maker('complete', N => 4);
ok(matches($g, "1-2,1-3,1-4,2-3,2-4,3-4", 1));
ok(directedok($g));

# undirected
$g = new Graph::Maker('complete', N => 4, undirected => 1);
ok(matches($g, "1-2,1-3,1-4,2-3,2-4,3-4", 0));
