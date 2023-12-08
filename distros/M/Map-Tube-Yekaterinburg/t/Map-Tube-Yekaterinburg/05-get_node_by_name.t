use strict;
use warnings;

use Encode qw(decode_utf8);
use English;
use Map::Tube::Yekaterinburg;
use Test::More tests => 4;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Yekaterinburg->new;
eval {
	$map->get_node_by_name;
};
like($EVAL_ERROR, qr{^Map::Tube::get_node_by_name\(\): ERROR: Missing Station Name. \(status: 100\)},
	'Get node for undefined node name.');

# Test.
eval {
	$map->get_node_by_name('foo');
};
like($EVAL_ERROR, qr{^Map::Tube::get_node_by_name\(\): ERROR: Invalid Station Name \[foo\]. \(status: 101\)},
	'Get node for bad node name.');

# Test.
my @ret = sort map { $_->id } $map->get_node_by_name(decode_utf8('Уральская'));
is_deeply(
	\@ret,
	[
		'1-04',
	],
	"Get all nodes for 'Уральская'.",
);
