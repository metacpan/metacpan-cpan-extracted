use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 109;
use Test::NoWarnings;
use Test::Warn;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000087983.mrc')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
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

# Test.
$marc_data = slurp($data->file('cnb000750997.mrc')->s);
warning_like
	{
		$obj = MARC::Convert::Wikidata::Transform->new(
			'marc_record' => MARC::Record->new_from_usmarc($marc_data),
		);
	}
	qr{^Edition number 'Lidové vydání' cannot clean\.},
	"Test of warning about 'Lidové vydání' edition number.",
;
$ret = $obj->object;
$author = $ret->authors->[0];
is($author->name, 'Karel', 'Krakatit: Get author name.');
is($author->surname, decode_utf8('Čapek'), 'Krakatit: Get author surname.');
is($author->date_of_birth, 1890, 'Krakatit: Get author date of birth.');
is($author->date_of_death, 1938, 'Krakatit: Get author date of death.');
$author_ext_ids_ar = $author->external_ids;
is(@{$author_ext_ids_ar}, 1, 'Krakatit: Get author external ids count (1).');
is($author_ext_ids_ar->[0]->name, 'nkcr_aut', 'Krakatit: Get author external value name (nkcr_aut).');
is($author_ext_ids_ar->[0]->value, 'jk01021023', 'Krakatit: Get author NKCR id (jk01021023).');
is($ret->edition_number, undef, 'Krakatit: Get edition number.');
is_deeply($ret->editors, [], 'Krakatit: Get editors.');
$external_ids_ar = $ret->external_ids;
is(@{$external_ids_ar}, 2, 'Krakatit: Get external ids count (2).');
is($external_ids_ar->[0]->name, 'cnb', 'Krakatit: Get external value name (cnb).');
is($external_ids_ar->[0]->value, 'cnb000750997', 'Krakatit: Get ČČNB number (cnb000750997).');
is($external_ids_ar->[1]->name, 'lccn', 'Krakatit: Get external value name (lccn).');
is($external_ids_ar->[1]->value, '3791532', 'Krakatit: Get ICCN number (3791532).');
is_deeply($ret->illustrators, [], 'Krakatit: Get illustrators.');
is_deeply($ret->isbns, [], 'Krakatit: Get ISBN-10.');
is_deeply($ret->krameriuses, [], 'Krakatit: Get Kramerius objects.');
is_deeply($ret->languages, ['cze'], 'Krakatit: Get language.');
is($ret->number_of_pages, 377, 'Krakatit: Get number of pages.');
is($ret->publication_date, 1939, 'Krakatit: Get publication date.');
is($ret->publishers->[0]->name, decode_utf8('Fr. Borový'), 'Krakatit: Get publisher.');
is($ret->publishers->[0]->place, 'Praha', 'Krakatit: Get publisher place.');
is_deeply($ret->subtitles, [decode_utf8('Román')], 'Krakatit: Get subtitles.');
is($ret->title, 'Krakatit', 'Krakatit: Get title.');
is_deeply($ret->translators, [], 'Krakatit: Get translators.');
# TODO book series
# TODO book series series ordinal
# TODO Kramerius link

# Test.
$marc_data = slurp($data->file('cnb000576456.mrc')->s);
$obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
$ret = $obj->object;
$author = $ret->authors->[0];
is($author->name, 'Jan', 'Broučci: Get author name.');
is($author->surname, decode_utf8('Karafiát'), 'Broučci: Get author surname.');
is($author->date_of_birth, 1846, 'Broučci: Get author date of birth.');
is($author->date_of_death, 1929, 'Broučci: Get author date of death.');
$author_ext_ids_ar = $author->external_ids;
is(@{$author_ext_ids_ar}, 1, 'Broučci: Get author external ids count (1).');
is($author_ext_ids_ar->[0]->name, 'nkcr_aut', 'Broučci: Get author external value name (nkcr_aut).');
is($author_ext_ids_ar->[0]->value, 'jk01052941', 'Broučci: Get author NKCR id (jk01052941).');
is($ret->edition_number, 2, 'Broučci: Get edition number.');
is_deeply($ret->editors, [], 'Broučci: Get editors.');
$external_ids_ar = $ret->external_ids;
is(@{$external_ids_ar}, 1, 'Broučci: Get external ids count (2).');
is($external_ids_ar->[0]->name, 'cnb', 'Broučci: Get external value name (cnb).');
is($external_ids_ar->[0]->value, 'cnb000576456', 'Broučci: Get ČČNB number (cnb000576456).');
is_deeply($ret->illustrators, [], 'Broučci: Get illustrators.');
is_deeply($ret->isbns, [], 'Broučci: Get ISBN-10.');
is_deeply($ret->krameriuses, [], 'Broučci: Get Kramerius objects.');
is_deeply($ret->languages, ['cze'], 'Broučci: Get language.');
is($ret->number_of_pages, 85, 'Broučci: Get number of pages.');
# TODO + ?
is($ret->publication_date, 1919, 'Broučci: Get publication date.');
is($ret->publishers->[0]->name, 'Alois Hynek', 'Broučci: Get publisher.');
is($ret->publishers->[0]->place, 'Praha', 'Broučci: Get publisher place.');
is_deeply($ret->subtitles, [decode_utf8('pro malé i veliké děti')], 'Broučci: Get subtitles.');
is($ret->title, decode_utf8('Broučci'), 'Broučci: Get title.');
is_deeply($ret->translators, [], 'Broučci: Get translators.');

# Test
$marc_data = slurp($data->file('cnb001756719.xml')->s);
$obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
$ret = $obj->object;
$author = $ret->authors->[0];
is($author->name, '', 'Učebnice práva ve čtyřech knihách: Get author name.');
is($author->surname, 'Gaius', 'Učebnice práva ve čtyřech knihách: Get author surname.');
is($author->date_of_birth, undef, 'Učebnice práva ve čtyřech knihách: Get author date of birth.');
is($author->date_of_death, undef, 'Učebnice práva ve čtyřech knihách: Get author date of death.');
is($author->work_period_start, 110, 'Učebnice práva ve čtyřech knihách: Get author work period start.');
is($author->work_period_end, 180, 'Učebnice práva ve čtyřech knihách: Get author work period end.');
$author_ext_ids_ar = $author->external_ids;
is(@{$author_ext_ids_ar}, 1, 'Učebnice práva ve čtyřech knihách: Get author external ids count (1).');
is($author_ext_ids_ar->[0]->name, 'nkcr_aut', 'Učebnice práva ve čtyřech knihách: Get author external value name (nkcr_aut).');
is($author_ext_ids_ar->[0]->value, 'jn19990002527', 'Učebnice práva ve čtyřech knihách: Get author NKCR id (jn19990002527).');

# Test.
$marc_data = slurp($data->file('cnb001042253.mrc')->s);
$obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
$ret = $obj->object;
$external_ids_ar = $ret->external_ids;
is(@{$external_ids_ar}, 4, 'Sněženka: Get external ids count (3).');
is($external_ids_ar->[0]->name, 'cnb', 'Sněženka: Get external value name (cnb).');
is($external_ids_ar->[0]->value, 'cnb001042253', 'Sněženka: Get ČČNB number (cnb001042253).');
is($external_ids_ar->[1]->name, 'cnb', 'Sněženka: Get external value name (cnb).');
is($external_ids_ar->[1]->value, 'cnb001250271', 'Sněženka: Get ČČNB number (cnb001250271).');
is($external_ids_ar->[1]->deprecated, 1, 'Sněženka: Get ČČNB number deprecation (1).');
is($external_ids_ar->[2]->name, 'lccn', 'Sněženka: Get external value name (lccn).');
is($external_ids_ar->[2]->value, '85710900', 'Sněženka: Get LCCN number (85710900).');
is($external_ids_ar->[3]->name, 'lccn', 'Sněženka: Get external value name (lccn).');
is($external_ids_ar->[3]->value, '85018016', 'Sněženka: Get LCCN number (85018016).');
