use strict;
use warnings;

use MARC::Convert::Wikidata::Item::BookEdition;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::Item::BookEdition::VERSION, 0.11, 'Version.');
