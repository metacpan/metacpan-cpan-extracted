use strict;
use warnings;

use MARC::Convert::Wikidata::Object::ExternalId;
use MARC::Convert::Wikidata::Object::People;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::People->new;
my $ret = $obj->external_ids;
is_deeply($ret, [], 'Get external ids ([] - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::People->new(
	external_ids => [
		MARC::Convert::Wikidata::Object::ExternalId->new(
			'name' => 'nkcr_aut',
			'value' => 'jk01033252',
		),
	],
	surname => 'Halouzka',
);
$ret = $obj->external_ids;
is(@{$ret}, 1, 'Get external ids count (1).');
isa_ok($ret->[0], 'MARC::Convert::Wikidata::Object::ExternalId');
is($ret->[0]->name, 'nkcr_aut', 'Get external id name (nkcr_aut).');
is($ret->[0]->value, 'jk01033252', 'Get external id value (jk01033252).');
