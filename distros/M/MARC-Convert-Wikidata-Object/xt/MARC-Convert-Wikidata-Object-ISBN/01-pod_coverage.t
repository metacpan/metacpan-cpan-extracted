use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('MARC::Convert::Wikidata::Object::ISBN',
	{ 'also_private' => ['BUILD'] },
	'MARC::Convert::Wikidata::Object::ISBN is covered.');
