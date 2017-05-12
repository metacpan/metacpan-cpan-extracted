use strict;
use warnings;
use Test::More tests => 3;

use Graph;
use Graph::Maker;
use Graph::Maker::BalancedTree;

require 't/matches.pl';

my $g;

# directed
$g = new Graph::Maker('balanced_tree', fan_out => 3, height => 3);
ok(matches($g, "1-2,1-3,1-4,2-5,2-6,2-7,3-8,3-9,3-10,4-11,4-12,4-13", 1));
ok(directedok($g));

# undirected
$g = new Graph::Maker('balanced_tree', fan_out => 3, height => 3, undirected => 1);
ok(matches($g, "1-2,1-3,1-4,2-5,2-6,2-7,3-8,3-9,3-10,4-11,4-12,4-13", 0));
