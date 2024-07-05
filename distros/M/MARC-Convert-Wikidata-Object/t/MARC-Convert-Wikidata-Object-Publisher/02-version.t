use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Publisher;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::Object::Publisher::VERSION, 0.05, 'Version.');
