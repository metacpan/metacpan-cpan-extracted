use strict;
use warnings;
use Test::More tests => 3;

use Graph;
use Graph::Maker;
use Graph::Maker::Star;

require 't/matches.pl';

my $g;

# directed
$g = new Graph::Maker('star', N => 4);
ok(matches($g, "1-2,1-3,1-4", 1));
ok(directedok($g));

# undirected
$g = new Graph::Maker('star', N => 4, undirected => 1);
ok(matches($g, "1-2,1-3,1-4", 0));
