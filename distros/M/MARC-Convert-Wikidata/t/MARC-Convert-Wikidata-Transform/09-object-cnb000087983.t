use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 41;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000087983.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	# XXX
	'ignore_data_errors' => 1,
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
my $author = $ret->authors->[0];
is($author->name, 'Elias', 'Masa a moc: Get author name.');
is($author->surname, 'Canetti', 'Masa a moc: Get author surname.');
is($author->date_of_birth, 1905, 'Masa a moc: Get author date of birth.');
is($author->date_of_death, 1994, 'Masa a moc: Get author date of death.');
my $author_ext_ids_ar = $author->external_ids;
is(@{$author_ext_ids_ar}, 1, 'Masa a moc: Get author external ids count (1).');
is($author_ext_ids_ar->[0]->name, 'nkcr_aut', 'Masa a moc: Get author external value name (nkcr_aut).');
is($author_ext_ids_ar->[0]->value, 'jn19990001316', 'Masa a moc: Get author NKCR id (jn19990001316).');
is($ret->edition_number, 1, 'Masa a moc: Get edition number.');
is_deeply($ret->editors, [], 'Masa a moc: Get editors.');
my $external_ids_ar = $ret->external_ids;
is(@{$external_ids_ar}, 2, 'Masa a moc: Get external ids count (2).');
is($external_ids_ar->[0]->name, 'cnb', 'Masa a moc: Get external value name (cnb).');
is($external_ids_ar->[0]->value, 'cnb000087983', 'Masa a moc: Get ČČNB number (cnb000087983).');
is($external_ids_ar->[1]->name, 'lccn', 'Masa a moc: Get external value name (lccn).');
is($external_ids_ar->[1]->value, '39576885', 'Masa a moc: Get ICCN number (39576885).');
is_deeply($ret->illustrators, [], 'Masa a moc: Get illustrators.');
is_deeply($ret->languages, ['cze'], 'Masa a moc: Get language.');
is($ret->isbns->[0]->isbn, '80-85812-08-8', 'Masa a moc: Get ISBN-10.');
my $kramerius = $ret->krameriuses->[0];
is($kramerius->kramerius_id, 'mzk', 'Masa a moc: Get Kramerius system id.');
is($kramerius->object_id, 'dec885c0-51fc-11e5-bf4b-005056827e51',
	'Masa a moc: Get Kramerius object id.');
is($kramerius->url,
	'http://kramerius.mzk.cz/search/handle/uuid:dec885c0-51fc-11e5-bf4b-005056827e51',
	'Masa a moc: Get Kramerius object link.');
is($ret->number_of_pages, 575, 'Masa a moc: Get number of pages.');
is($ret->publication_date, 1994, 'Masa a moc: Get publication date.');
is($ret->publishers->[0]->name, 'Arcadia', 'Masa a moc: Get publisher.');
is($ret->publishers->[0]->place, 'Praha', 'Masa a moc: Get publisher place.');
is_deeply($ret->subtitles, [], 'Masa a moc: Get subtitles.');
is($ret->title, 'Masa a moc', 'Masa a moc: Get title.');
my $translator = $ret->translators->[0];
is($translator->name, decode_utf8('Jiří'), 'Masa a moc: Get translator name.');
is($translator->surname, decode_utf8('Stromšík'), 'Masa a moc: Get translator surname.');
is($translator->date_of_birth, 1939, 'Masa a moc: Get translator date of birth.');
is($translator->date_of_death, undef, 'Masa a moc: Get translator date of death.');
my $translator_ext_ids_ar = $translator->external_ids;
is(@{$translator_ext_ids_ar}, 1, 'Masa a moc: Get author external ids count (1).');
is($translator_ext_ids_ar->[0]->name, 'nkcr_aut', 'Masa a moc: Get translator external value name (nkcr_aut).');
is($translator_ext_ids_ar->[0]->value, 'jk01121492', 'Masa a moc: Get translator NKCR id (jk01121492).');
my $kramerius_link = $ret->krameriuses->[0];
is($kramerius_link->kramerius_id, 'mzk', 'Masa a moc: Get Kramerius system id.');
is($kramerius_link->object_id, 'dec885c0-51fc-11e5-bf4b-005056827e51', 'Masa a moc: Get Kramerius uuid.');
is($kramerius_link->url, 'http://kramerius.mzk.cz/search/handle/uuid:dec885c0-51fc-11e5-bf4b-005056827e51', 'Masa a moc: Get Kramerius URL.');
my $serie = $ret->series->[0];
is($serie->name, 'Studio klasik', 'Masa a moc: Get series name.');
is($serie->series_ordinal, 1, 'Masa a moc: Get series ordinal.');
my $pub = $serie->publisher;
is($serie->publisher->name, 'Arcadia', 'Masa a moc: Get series publisher name.');
is($serie->publisher->place, 'Praha', 'Masa a moc: Get series publisher place.');
