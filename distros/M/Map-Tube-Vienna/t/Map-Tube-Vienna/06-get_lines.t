# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Vienna;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Vienna->new;
my $ret_ar = $map->get_lines;
my @sorted = sort @{$ret_ar};
is_deeply(
	\@sorted,
	[
		'U-Bahn-Linie U1',
		'U-Bahn-Linie U2',
		'U-Bahn-Linie U3',
		'U-Bahn-Linie U4',
		'U-Bahn-Linie U6',
	],
	'Get lines.',
);
