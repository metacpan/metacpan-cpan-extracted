use strict;
use warnings;
use Test::More tests => 3;

use Graph;
use Graph::Maker;
use Graph::Maker::Barbell;

require 't/matches.pl';

my $g;

# directed
$g = new Graph::Maker('barbell', N1 => 4, N2 => 2);
ok(matches($g, "1-2,1-3,1-4,2-3,2-4,3-4,4-5,5-6,6-7,7-8,7-9,7-10,8-9,8-10,9-10", 1));
ok(directedok($g));

# undirected
$g = new Graph::Maker('barbell', N1 => 4, N2 => 2, undirected => 1);
ok(matches($g, "1-2,1-3,1-4,2-3,2-4,3-4,4-5,5-6,6-7,7-8,7-9,7-10,8-9,8-10,9-10", 0));
