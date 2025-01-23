use strict;
use warnings;

use English;
use Map::Tube::Singapore;
use Test::More tests => 4;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Singapore->new;
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
my @ret = sort map { $_->id } $map->get_node_by_name('Yew Tee');
is_deeply(
	\@ret,
	[
		'NS5',
	],
	"Get all nodes for 'Yew Tee'.",
);
