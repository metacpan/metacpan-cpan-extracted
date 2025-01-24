use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Samara;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Samara->new;
my $ret_ar = $map->get_lines;
my @sorted = sort @{$ret_ar};
is_deeply(
	\@sorted,
	[
		decode_utf8('Первая линия'),
	],
	'Get lines.',
);
