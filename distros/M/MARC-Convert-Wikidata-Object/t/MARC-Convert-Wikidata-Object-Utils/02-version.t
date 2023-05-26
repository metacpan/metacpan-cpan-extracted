use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::Object::Utils::VERSION, 0.01, 'Version.');
