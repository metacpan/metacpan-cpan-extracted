use strict;
use warnings;

use MARC::Convert::Wikidata::Object::ISBN;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '978-1-61189-009-9',
);
my $ret = $obj->cover;
is($ret, undef, 'Get ISBN cover (undef - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'cover' => 'hardback',
	'isbn' => '80-270-8205-6',
);
$ret = $obj->cover;
is($ret, 'hardback', 'Get ISBN cover (hardback).');
