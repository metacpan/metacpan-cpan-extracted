use Test::More tests => 2;
BEGIN { use_ok('JSON::Hyper') };

use JSON;

my $hyper = JSON::Hyper->new(<<'SCHEMA');
{
	"links": [
		{
			"rel":  "self",
			"href": "{id}"
		},
		{
			"rel":  "up",
			"href": "{upId}"
		},
		{
			"rel":  "help",
			"href": "{helpId}"
		},
		{
			"rel":  "children",
			"href": "find_children?id={id}"
		},
		{
			"rel":  "meta",
			"href": "relationship_history?id1={id}&id2={upId}"
		}
	]
}
SCHEMA

my $object = from_json(<<'OBJECT');
{
	"id":   "lemons",
	"upId": "citrus_fruits"
}
OBJECT

my @got = sort { $a->{rel} cmp $b->{rel} }
	$hyper->find_links($object, 'http://example.com/food/');

my @expected = (
	JSON::Hyper::Link->new({
		'rel' => 'children',
		'enctype' => undef,
		'href' => 'http://example.com/food/find_children?id=lemons',
		'method' => undef,
		'schema' => undef,
		'properties' => undef,
		'targetSchema' => undef
	}),
	JSON::Hyper::Link->new({
		'rel' => 'meta',
		'enctype' => undef,
		'href' => 'http://example.com/food/relationship_history?id1=lemons&id2=citrus_fruits',
		'method' => undef,
		'schema' => undef,
		'properties' => undef,
		'targetSchema' => undef
	}),
	JSON::Hyper::Link->new({
		'rel' => 'self',
		'enctype' => undef,
		'href' => 'http://example.com/food/lemons',
		'method' => undef,
		'schema' => undef,
		'properties' => undef,
		'targetSchema' => undef
	}),
	JSON::Hyper::Link->new({
		'rel' => 'up',
		'enctype' => undef,
		'href' => 'http://example.com/food/citrus_fruits',
		'method' => undef,
		'schema' => undef,
		'properties' => undef,
		'targetSchema' => undef
	}),
);

is_deeply(\@got, \@expected, 'Returned correct data.');
