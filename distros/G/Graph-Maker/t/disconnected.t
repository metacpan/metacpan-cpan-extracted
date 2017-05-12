use strict;
use warnings;
use Test::More tests => 3;

use Graph;
use Graph::Maker;
use Graph::Maker::Disconnected;

require 't/matches.pl';

my $g;

# directed
$g = new Graph::Maker('disconnected', N => 4);
ok(matches($g, "1,2,3,4", 1));
ok(directedok($g));

# undirected
$g = new Graph::Maker('disconnected', N => 4, undirected => 1);
ok(matches($g, "1,2,3,4", 0));
