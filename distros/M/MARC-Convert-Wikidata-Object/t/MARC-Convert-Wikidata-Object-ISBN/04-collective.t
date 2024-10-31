use strict;
use warnings;

use MARC::Convert::Wikidata::Object::ISBN;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '978-1-61189-009-9',
);
my $ret = $obj->collective;
is($ret, 0, 'Get ISBN collective flag (0 - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'collective' => 1,
	'isbn' => '80-270-8205-6',
);
$ret = $obj->collective;
is($ret, 1, 'Get ISBN collective (1).');
