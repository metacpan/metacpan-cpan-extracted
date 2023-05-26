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
	$obj->directors,
	[],
	'Get default directors list.',
);

# Test.
my $director = MARC::Convert::Wikidata::Object::People->new(
	date_of_birth => '1967',
	name => 'Jitka',
	nkcr_aut => 'mzk2007382100',
	surname => decode_utf8('Škápíková'),
);
$obj = MARC::Convert::Wikidata::Object->new(
	'directors' => [$director],
);
my @directors = $obj->directors;
is(@directors, 1, 'Get number of directors.');
