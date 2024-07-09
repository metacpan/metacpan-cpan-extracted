use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::People;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is_deeply(
	$obj->translators,
	[],
	'Get default translators list.',
);

# Test.
my $translator = MARC::Convert::Wikidata::Object::People->new(
	'date_of_birth' => 1939,
	'name' => decode_utf8('Jiří'),
	'nkcr_aut' => 'jk01121492',
	'surname' => decode_utf8('Stromšík'),
);
$obj = MARC::Convert::Wikidata::Object->new(
	'translators' => [$translator],
);
my @translators = $obj->translators;
is(@translators, 1, 'Get number of translators.');
