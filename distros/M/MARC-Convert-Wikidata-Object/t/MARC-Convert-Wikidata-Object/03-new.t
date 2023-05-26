use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::People;
use MARC::Convert::Wikidata::Object::Publisher;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
isa_ok($obj, 'MARC::Convert::Wikidata::Object');

# Test.
my $author = MARC::Convert::Wikidata::Object::People->new(
	'date_of_birth' => '1814',
	'date_of_death' => '1883',
	'name' => decode_utf8('Antonín'),
	'nkcr_aut' => 'jk01033252',
	'surname' => 'Halouzka',
);
my $editor = MARC::Convert::Wikidata::Object::People->new(
	'date_of_birth' => '1814',
	'date_of_death' => '1883',
	'name' => decode_utf8('Antonín'),
	'nkcr_aut' => 'jk01033252',
	'surname' => 'Halouzka',
);
my $illustrator = MARC::Convert::Wikidata::Object::People->new(
	'date_of_birth' => 1853,
	'date_of_death' => 1932,
	'name' => 'Hans',
	'nkcr_aut' => 'xx0104411',
	'surname' => 'Tegner',
);
my $translator = MARC::Convert::Wikidata::Object::People->new(
	'date_of_birth' => 1939,
	'name' => decode_utf8('Jiří'),
	'nkcr_aut' => 'jk01121492',
	'surname' => decode_utf8('Stromšík'),
);
my $publisher = MARC::Convert::Wikidata::Object::Publisher->new(
	'name' => decode_utf8('Fr. Borový'),
	'place' => 'Praha',
);
$obj = MARC::Convert::Wikidata::Object->new(
	'authors' => [$author],
	'ccnb' => 'cnb000750997',
	'edition_number' => 1,
	'editors' => [$editor],
	'illustrators' => [$illustrator],
	'isbn_10' => '80-85812-08-8',
	'isbn_13' => '978-80-85812-08-4',
	'languages' => ['cze'],
	'number_of_pages' => 10,
	'publication_date' => 1925,
	'publishers' => [$publisher],
	'subtitles' => [decode_utf8('Román')],
	'title' => 'Krakatit',
	'translators' => [$translator],
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object', 'Full object.');
