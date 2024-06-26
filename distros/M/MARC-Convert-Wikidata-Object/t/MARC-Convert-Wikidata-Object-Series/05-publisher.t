use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Publisher;
use MARC::Convert::Wikidata::Object::Series;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::Series->new(
	'name' => 'book series',
);
my $ret = $obj->publisher;
is($ret, undef, 'Get default publisher of series.');

# Test.
$obj = MARC::Convert::Wikidata::Object::Series->new(
	'name' => 'book series',
	'publisher' => MARC::Convert::Wikidata::Object::Publisher->new(
		'name' => 'Grada',
	),
);
$ret = $obj->publisher;
isa_ok($ret, 'MARC::Convert::Wikidata::Object::Publisher');
