# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use Map::Tube::KualaLumpur;
use Test::More tests => 4;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::KualaLumpur->new;
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
my @ret = sort map { $_->id } $map->get_node_by_name('KL Sentral');
is_deeply(
	\@ret,
	[
		'6-01',
		'7-01',
		'KA01',
		'KJ15',
		'MR1',
	],
	"Get all nodes for 'KL Sentral name'.",
);
