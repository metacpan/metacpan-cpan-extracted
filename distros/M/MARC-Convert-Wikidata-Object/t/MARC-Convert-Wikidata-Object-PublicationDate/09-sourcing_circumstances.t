use strict;
use warnings;

use MARC::Convert::Wikidata::Object::PublicationDate;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'date' => '2010',
);
is($obj->sourcing_circumstances, undef, 'Get sourcing circumstances (undef - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'date' => '2010',
	'sourcing_circumstances' => 'circa',
);
is($obj->sourcing_circumstances, 'circa', 'Get sourcing circumstances (circa).');
