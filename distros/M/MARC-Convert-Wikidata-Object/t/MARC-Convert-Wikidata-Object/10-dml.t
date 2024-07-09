use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is($obj->dml, undef, 'Get default DML id.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'dml' => 402812,
	'title' => decode_utf8('Geometrické pravděpodobnosti'),
);
is($obj->dml, 402812, 'Get DML id (402812).');
