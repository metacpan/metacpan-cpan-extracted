use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('MARC::Convert::Wikidata::Item::AudioBook');
}

# Test.
require_ok('MARC::Convert::Wikidata::Item::AudioBook');
