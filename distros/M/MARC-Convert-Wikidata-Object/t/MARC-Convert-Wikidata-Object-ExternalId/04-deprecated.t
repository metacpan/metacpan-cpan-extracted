use strict;
use warnings;

use MARC::Convert::Wikidata::Object::ExternalId;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::ExternalId->new(
	'name' => 'cnb',
	'value' => 'cnb003597104',
);
is($obj->deprecated, 0, 'Get deprecated value (0 - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::ExternalId->new(
	'deprecated' => 1,
	'name' => 'cnb',
	'value' => 'cnb003597104',
);
is($obj->deprecated, 1, 'Get deprecated value (1).');
