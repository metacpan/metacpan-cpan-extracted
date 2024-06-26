use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Convert::Wikidata::Object::Publisher;
use MARC::Convert::Wikidata::Object::Series;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::Series->new(
	'name' => 'book series',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::Series');

# Test.
$obj = MARC::Convert::Wikidata::Object::Series->new(
	'name' => 'book series',
	'publisher' => MARC::Convert::Wikidata::Object::Publisher->new(
		'name' => 'Publisher',
	),
	'series_ordinal' => 1,
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::Series');

# Test.
eval {
	MARC::Convert::Wikidata::Object::Series->new;
};
is($EVAL_ERROR, "Parameter 'name' is required.\n",
	"Parameter 'name' is required.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::Series->new(
		'name' => 'Series',
		'publisher' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'publisher' must be a 'MARC::Convert::Wikidata::Object::Publisher' object.\n",
	"Parameter 'publisher' must be a 'MARC::Convert::Wikidata::Object::Publisher' object (bad).");
clean();
