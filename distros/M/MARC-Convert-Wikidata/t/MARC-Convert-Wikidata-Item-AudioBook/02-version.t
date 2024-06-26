use strict;
use warnings;

use MARC::Convert::Wikidata::Item::AudioBook;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::Item::AudioBook::VERSION, 0.1, 'Version.');
