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
is($obj->start_time, undef, 'Get start time (undef).');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'start_time' => '2010',
);
is($obj->start_time, '2010', 'Get start time (2010).');
