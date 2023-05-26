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
	$obj->photographers,
	[],
	'Get default photographers list.',
);

# Test.
my $photographer = MARC::Convert::Wikidata::Object::People->new(
	'date_of_birth' => '1952',
	'date_of_death' => '2009',
	'name' => 'Renco',
	'nkcr_aut' => 'xx0189222',
	'surname' => decode_utf8('Kosinožić'),
);
$obj = MARC::Convert::Wikidata::Object->new(
	'photographers' => [$photographer],
);
my @photographers = $obj->photographers;
is(@photographers, 1, 'Get number of photoigraphers.');
