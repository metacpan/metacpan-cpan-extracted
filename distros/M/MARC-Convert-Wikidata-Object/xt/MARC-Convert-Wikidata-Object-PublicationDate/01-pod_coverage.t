use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('MARC::Convert::Wikidata::Object::PublicationDate',
	{ 'also_private' => ['BUILD'] },
	'MARC::Convert::Wikidata::Object::PublicationDate is covered.');
