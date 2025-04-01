use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is($obj->publication_date, undef, 'Get default date of publication.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'publication_date' => 1993,
);
is($obj->publication_date, 1993, 'Get explicit date of publication.');
