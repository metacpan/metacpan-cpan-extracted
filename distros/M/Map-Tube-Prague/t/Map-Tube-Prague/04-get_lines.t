use strict;
use warnings;

use Map::Tube::Prague;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Prague->new;
my $ret_ar = $map->get_lines;
my @sorted = sort @{$ret_ar};
is_deeply(
	\@sorted,
	[
		'Linka A',
		'Linka B',
		'Linka C',
	],
	'Get lines.',
);
