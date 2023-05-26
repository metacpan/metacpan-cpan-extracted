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
	$obj->authors_of_afterword,
	[],
	'Get default authors of afterword list.',
);

# Test.
my $author = MARC::Convert::Wikidata::Object::People->new(
	date_of_birth => '1814',
	date_of_death => '1883',
	name => decode_utf8('Antonín'),
	nkcr_aut => 'jk01033252',
	surname => 'Halouzka',
);
$obj = MARC::Convert::Wikidata::Object->new(
	'authors_of_afterword' => [$author],
);
my @authors = $obj->authors_of_afterword;
is(@authors, 1, 'Get number of authors of afterword.');
