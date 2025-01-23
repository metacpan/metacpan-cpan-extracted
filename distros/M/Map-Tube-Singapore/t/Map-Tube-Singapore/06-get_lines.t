use strict;
use warnings;

use Map::Tube::Singapore;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Singapore->new;
my $ret_ar = $map->get_lines;
my @sorted = sort @{$ret_ar};
is_deeply(
	\@sorted,
	[
		'Circle MRT Line',
		'Downtown MRT Line',
		'East West MRT Line',
		'North East MRT Line',
		'North South MRT Line',
	],
	'Get lines.',
);
