use strict;
use warnings;

use MARC::Convert::Wikidata::Transform;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::Transform::VERSION, 0.32, 'Version.');
