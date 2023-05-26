use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Publisher;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::Publisher->new(
	'name' => 'Academia',
);
my $place = $obj->place;
is($place, undef, 'Get default value of place.');

# Test.
$obj = MARC::Convert::Wikidata::Object::Publisher->new(
	'name' => 'Academia',
	'place' => 'Praha',
);
$place = $obj->place;
is($place, 'Praha', 'Get place.');
