use strict;
use warnings;

use MARC::Convert::Wikidata::Object::ISBN;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '978-1-61189-009-9',
);
my $ret = $obj->isbn;
is($ret, '978-1-61189-009-9', 'Get ISBN number (13 characters).');

# Test.
$obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '80-270-8205-6',
);
$ret = $obj->isbn;
is($ret, '80-270-8205-6', 'Get ISBN number (10 characters).');
