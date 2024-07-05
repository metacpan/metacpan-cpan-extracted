use strict;
use warnings;

use MARC::Convert::Wikidata::Object::ExternalId;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::ExternalId->new(
	'name' => 'cnb',
	'value' => 'cnb003597104',
);
is($obj->value, 'cnb003597104', 'Get value (cnb003597104).');
