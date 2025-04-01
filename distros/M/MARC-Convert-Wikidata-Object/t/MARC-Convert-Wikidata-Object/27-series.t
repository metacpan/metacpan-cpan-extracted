use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::Series;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is_deeply($obj->series, [], 'Get default series.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'series' => [MARC::Convert::Wikidata::Object::Series->new(
		'name' => decode_utf8('Malé encyklopedie'),
	)],
);
is_deeply($obj->series->[0]->name, decode_utf8('Malé encyklopedie'),
	'Get explicit book series name.');
