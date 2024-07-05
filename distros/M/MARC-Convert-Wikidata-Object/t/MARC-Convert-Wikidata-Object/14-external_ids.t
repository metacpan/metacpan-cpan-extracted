use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::ExternalId;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
my $ret = $obj->external_ids;
is_deeply($ret, [], 'Get external ids ([] - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	external_ids => [
		MARC::Convert::Wikidata::Object::ExternalId->new(
			'name' => 'cnb',
			'value' => 'cnb001188266',
		),
	],
	surname => 'Halouzka',
);
$ret = $obj->external_ids;
is(@{$ret}, 1, 'Get external ids count (1).');
isa_ok($ret->[0], 'MARC::Convert::Wikidata::Object::ExternalId');
is($ret->[0]->name, 'cnb', 'Get external id name (cnb).');
is($ret->[0]->value, 'cnb001188266', 'Get external id value (cnb001188266).');
