use strict;
use warnings;

use MARC::Convert::Wikidata::Item;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::Item::VERSION, 0.01, 'Version.');
