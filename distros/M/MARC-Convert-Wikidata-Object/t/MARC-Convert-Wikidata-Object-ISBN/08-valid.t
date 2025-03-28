use strict;
use warnings;

use MARC::Convert::Wikidata::Object::ISBN;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '978-1-61189-009-9',
);
my $ret = $obj->valid;
is($ret, 1, 'Get ISBN valid flag (1 - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '80-270-8205-6',
	'valid' => 1,
);
$ret = $obj->valid;
is($ret, 1, 'Get ISBN valid flag (1).');

# Test.
$obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '80-270-8204-8',
	'valid' => 0,
);
$ret = $obj->valid;
is($ret, 0, 'Get ISBN valid flag (0).');
