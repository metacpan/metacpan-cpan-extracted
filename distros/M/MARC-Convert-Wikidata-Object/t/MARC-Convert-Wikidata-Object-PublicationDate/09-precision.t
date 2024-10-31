use strict;
use warnings;

use MARC::Convert::Wikidata::Object::PublicationDate;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'date' => '2010',
);
is($obj->precision, 'day', 'Get precision (day - default in case of date).');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'date' => '2010',
	'precision' => 'decade',
);
is($obj->precision, 'decade', 'Get precision (decade).');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'earliest_date' => '2010',
);
is($obj->precision, undef, 'Get precision (undef - default without date).');
