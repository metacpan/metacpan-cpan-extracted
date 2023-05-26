use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Kramerius;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Convert::Wikidata::Object::Kramerius::VERSION, 0.01, 'Version.');
