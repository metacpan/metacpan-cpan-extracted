use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Series;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = MARC::Convert::Wikidata::Object::Series->new(
	'issn' => '0585-5675',
	'name' => decode_utf8('Studie a práce lingvistické'),
);

is($obj->issn, '0585-5675', 'Get ISSN.');
is($obj->name, decode_utf8('Studie a práce lingvistické'), 'Get name of series.');
