use strict;
use warnings;

use MARC::Convert::Wikidata::Object::PublicationDate;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'start_time' => '2010',
	'end_time' => '2012',
);
is($obj->earliest_date, undef, 'Get earliest date (undef).');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'earliest_date' => '2010',
);
is($obj->earliest_date, '2010', 'Get earliest date (2010).');
