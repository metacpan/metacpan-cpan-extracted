use strict;
use warnings;

use MARC::Convert::Wikidata::Object::ISBN;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '978-1-61189-009-9',
);
my $ret = $obj->type;
is($ret, 13, 'Get ISBN type (13).');

# Test.
$obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '80-270-8205-6',
);
$ret = $obj->type;
is($ret, 10, 'Get ISBN type (10).');
