use strict;
use warnings;
use Test::More;

plan tests => 1 unless $::NO_PLAN && $::NO_PLAN;

# use List::Util 'pairmap';
use List::Pairwise 'mapp';

use strict;
use warnings;

# pairmap {
mapp {
	my $name = $a;
	is($a, 1, "key still defined after assignement? (List-Util bug)");
}
map {
	my $len = length;
	$_
} (1,2)