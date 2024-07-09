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
	$obj->narrators,
	[],
	'Get default narrators list.',
);

# Test.
my $narrator = MARC::Convert::Wikidata::Object::People->new(
	'date_of_birth' => 1973,
	'name' => 'Hynek',
	'nkcr_aut' => 'js20050801019',
	'surname' => decode_utf8('Čermák'),
);
$obj = MARC::Convert::Wikidata::Object->new(
	'narrators' => [$narrator],
);
my @narrators = $obj->narrators;
is(@narrators, 1, 'Get number of narrators.');
