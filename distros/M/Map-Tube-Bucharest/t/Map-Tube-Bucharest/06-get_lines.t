# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Bucharest;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Bucharest->new;
my $ret_ar = $map->get_lines;
my @sorted = sort @{$ret_ar};
is_deeply(
	\@sorted,
	[
		'Linia M1',
		'Linia M2',
		'Linia M3',
		'Linia M4',
	],
	'Get lines.',
);
