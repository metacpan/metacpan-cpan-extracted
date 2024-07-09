use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::Kramerius;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is_deeply(
	$obj->krameriuses,
	[],
	'Get default Krameriuses list.',
);

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'krameriuses' => [
		MARC::Convert::Wikidata::Object::Kramerius->new(
			'kramerius_id' => 'nkp',
			'object_id' => '814e66a0-b6df-11e6-88f6-005056827e52',
		),
	],
);
my @krameriuses = $obj->krameriuses;
is(@krameriuses, 1, 'Get number of Kramerius systems.');
