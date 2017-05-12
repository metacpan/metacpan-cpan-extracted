use strict;
use warnings;
use Test::More tests => 3;

use Graph;
use Graph::Maker;
use Graph::Maker::Disk;

require 't/matches.pl';

my $g;

# directed
$g = new Graph::Maker('disk', disks => 2, init => 3);
ok(matches($g, "1-2,1-3,1-4,2-3,3-4,4-2,5-6,6-7,7-8,8-9,9-10,10-5,2-5,2-6,3-7,3-8,4-9,4-10", 1));
ok(directedok($g));

# undirected
$g = new Graph::Maker('disk', disks => 2, init => 3, undirected => 1);
ok(matches($g, "1-2,1-3,1-4,2-3,3-4,4-2,5-6,6-7,7-8,8-9,9-10,10-5,2-5,2-6,3-7,3-8,4-9,4-10", 0));

my $o = $g->get_vertex_attribute(1, 'pos');
my $t = $g->get_vertex_attribute(2, 'pos');
my $f = $g->get_vertex_attribute(5, 'pos');

