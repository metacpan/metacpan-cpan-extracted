use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Convert::Wikidata::Object::ExternalId;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::ExternalId->new(
	'deprecated' => 0,
	'name' => 'cnb',
	'value' => 'cnb003597104',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::ExternalId');

# Test.
eval {
	MARC::Convert::Wikidata::Object::ExternalId->new(
		'deprecated' => 'bad',
		'name' => 'cnb',
		'value' => 'cnb003597104',
	);
};
is($EVAL_ERROR, "Parameter 'deprecated' must be a bool (0/1).\n",
	"Parameter 'deprecated' must be a bool (0/1).");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::ExternalId->new(
		'name' => 'xxx',
		'value' => 'cnb003597104',
	);
};
is($EVAL_ERROR, "Parameter 'name' must be one of defined strings.\n",
	"Parameter 'name' must be one of defined strings.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::ExternalId->new(
		'value' => 'cnb003597104',
	);
};
is($EVAL_ERROR, "Parameter 'name' is required.\n",
	"Parameter 'name' is required.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::ExternalId->new(
		'name' => 'cnb',
	);
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();
