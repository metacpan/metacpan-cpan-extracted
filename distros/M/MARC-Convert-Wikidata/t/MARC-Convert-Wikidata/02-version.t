use strict;
use warnings;

use MARC::Convert::Wikidata;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::VERSION, 0.27, 'Version.');
