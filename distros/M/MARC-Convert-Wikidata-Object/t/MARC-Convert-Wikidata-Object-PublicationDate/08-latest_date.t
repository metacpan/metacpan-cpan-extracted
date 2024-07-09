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
is($obj->latest_date, undef, 'Get latest date (undef).');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'latest_date' => '2010',
);
is($obj->latest_date, '2010', 'Get latest date (2010).');
