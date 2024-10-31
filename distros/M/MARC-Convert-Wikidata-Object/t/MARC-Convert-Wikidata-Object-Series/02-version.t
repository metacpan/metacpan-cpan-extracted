use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Series;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::Object::Series::VERSION, 0.07, 'Version.');
