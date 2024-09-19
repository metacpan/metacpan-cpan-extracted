use strict;
use warnings;

use MARC::Convert::Wikidata::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::Utils::VERSION, 0.16, 'Version.');
