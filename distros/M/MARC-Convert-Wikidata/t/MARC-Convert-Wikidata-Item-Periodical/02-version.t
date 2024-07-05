use strict;
use warnings;

use MARC::Convert::Wikidata::Item::Periodical;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::Item::Periodical::VERSION, 0.13, 'Version.');
