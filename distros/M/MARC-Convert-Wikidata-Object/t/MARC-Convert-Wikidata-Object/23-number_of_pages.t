use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is($obj->number_of_pages, undef, 'Get default number of pages.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'number_of_pages' => 10,
);
is($obj->number_of_pages, 10, 'Get explicit number of pages.');
