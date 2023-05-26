use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Publisher;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::Publisher->new(
	'name' => 'Academia',
);
my $name = $obj->name;
is($name, 'Academia', 'Get name.');
