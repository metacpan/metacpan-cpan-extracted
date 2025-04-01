use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::Series;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is_deeply($obj->cycles, [], 'Get cyclces ([] - default).');

# Test.
my $cycle = MARC::Convert::Wikidata::Object::Series->new(
	'name' => 'Harry Potter',
);
$obj = MARC::Convert::Wikidata::Object->new(
	'cycles' => [$cycle],
);
is($obj->cycles->[0]->name, 'Harry Potter', 'Get cycle name (Harry Potter).');
