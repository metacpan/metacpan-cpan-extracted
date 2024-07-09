use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is($obj->edition_number, undef, 'Get default edition number.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'edition_number' => 1,
);
is($obj->edition_number, 1, 'Get explicit edition number.');
