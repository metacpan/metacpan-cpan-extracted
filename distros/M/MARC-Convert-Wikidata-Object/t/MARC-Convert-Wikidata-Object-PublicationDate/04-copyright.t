use strict;
use warnings;

use MARC::Convert::Wikidata::Object::PublicationDate;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'date' => '2010',
);
is($obj->copyright, 0, 'Get copyright (0 - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
	'copyright' => 1,
	'date' => '2010',
);
is($obj->copyright, 1, 'Get copyright (1).');
