use strict;
use warnings;

use MARC::Convert::Wikidata::Object::ISBN;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::Object::ISBN::VERSION, 0.05, 'Version.');
