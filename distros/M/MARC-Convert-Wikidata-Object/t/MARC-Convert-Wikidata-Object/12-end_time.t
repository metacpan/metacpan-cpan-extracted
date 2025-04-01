use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is($obj->end_time, undef, 'Get default end time.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'end_time' => 1993,
);
is($obj->end_time, 1993, 'Get explicit end_time.');
