use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is($obj->start_time, undef, 'Get default end time.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'start_time' => 1993,
);
is($obj->start_time, 1993, 'Get explicit start_time.');
