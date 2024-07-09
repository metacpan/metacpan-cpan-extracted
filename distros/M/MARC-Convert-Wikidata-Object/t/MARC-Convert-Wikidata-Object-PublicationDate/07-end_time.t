use strict;
use warnings;

use MARC::Convert::Wikidata::Object::PublicationDate;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'earliest_date' => '2010',
	'latest_date' => '2012',
);
is($obj->end_time, undef, 'Get end time (undef).');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'end_time' => '2010',
);
is($obj->end_time, '2010', 'Get end time (2010).');
