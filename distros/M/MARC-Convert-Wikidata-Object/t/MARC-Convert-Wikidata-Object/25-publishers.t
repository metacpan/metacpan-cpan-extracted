use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::Publisher;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is_deeply($obj->publishers, [], 'Get default publishers.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'publishers' => [MARC::Convert::Wikidata::Object::Publisher->new(
		'name' => decode_utf8('Vyšehrad'),
	)],
);
is_deeply($obj->publishers->[0]->name, decode_utf8('Vyšehrad'),
	'Get explicit publisher name.');
