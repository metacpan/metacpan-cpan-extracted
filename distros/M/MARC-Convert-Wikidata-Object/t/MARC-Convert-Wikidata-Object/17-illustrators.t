use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::People;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is_deeply(
	$obj->illustrators,
	[],
	'Get default illustrators list.',
);

# Test.
my $illustrator = MARC::Convert::Wikidata::Object::People->new(
	'date_of_birth' => 1853,
	'date_of_death' => 1932,
	'name' => 'Hans',
	'nkcr_aut' => 'xx0104411',
	'surname' => 'Tegner',
);
$obj = MARC::Convert::Wikidata::Object->new(
	'illustrators' => [$illustrator],
);
my @illustrators = $obj->illustrators;
is(@illustrators, 1, 'Get number of illustrators.');
