use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 30;
use Test::NoWarnings;
use Test::Warn;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000750997.mrc')->s);
my $obj;
warning_like
	{
		$obj = MARC::Convert::Wikidata::Transform->new(
			'marc_record' => MARC::Record->new_from_usmarc($marc_data),
		);
	}
	qr{^Edition number 'Lidové vydání' cannot clean\.},
	"Test of warning about 'Lidové vydání' edition number.",
;
my $ret = $obj->object;
my $author = $ret->authors->[0];
is($author->name, 'Karel', 'Krakatit: Get author name.');
is($author->surname, decode_utf8('Čapek'), 'Krakatit: Get author surname.');
is($author->date_of_birth, 1890, 'Krakatit: Get author date of birth.');
is($author->date_of_death, 1938, 'Krakatit: Get author date of death.');
my $author_ext_ids_ar = $author->external_ids;
is(@{$author_ext_ids_ar}, 1, 'Krakatit: Get author external ids count (1).');
is($author_ext_ids_ar->[0]->name, 'nkcr_aut', 'Krakatit: Get author external value name (nkcr_aut).');
is($author_ext_ids_ar->[0]->value, 'jk01021023', 'Krakatit: Get author NKCR id (jk01021023).');
is($ret->edition_number, undef, 'Krakatit: Get edition number.');
is_deeply($ret->editors, [], 'Krakatit: Get editors.');
my $external_ids_ar = $ret->external_ids;
is(@{$external_ids_ar}, 2, 'Krakatit: Get external ids count (2).');
is($external_ids_ar->[0]->name, 'cnb', 'Krakatit: Get external value name (cnb).');
is($external_ids_ar->[0]->value, 'cnb000750997', 'Krakatit: Get ČČNB id (cnb000750997).');
is($external_ids_ar->[1]->name, 'lccn', 'Krakatit: Get external value name (lccn).');
is($external_ids_ar->[1]->value, '3791532', 'Krakatit: Get ICCN id (3791532).');
is_deeply($ret->illustrators, [], 'Krakatit: Get illustrators.');
is_deeply($ret->isbns, [], 'Krakatit: Get ISBN-10.');
my $krameriuses_ar = $ret->krameriuses;
is(@{$krameriuses_ar}, 1, 'Krakatit: Get Krameriuses count (1).');
is($krameriuses_ar->[0]->kramerius_id, 'mzk', 'Krakatit: Get Kramerius id (mzk).');
is($krameriuses_ar->[0]->object_id, '26413e90-4eb4-11e8-afec-005056827e51',
	'Krakatit: Get Kramerius object_id (26413e90-4eb4-11e8-afec-005056827e51).');
is($krameriuses_ar->[0]->url, 'http://kramerius.mzk.cz/search/handle/uuid:26413e90-4eb4-11e8-afec-005056827e51',
	'Krakatit: Get Kramerius url (http://kramerius.mzk.cz/search/handle/uuid:26413e90-4eb4-11e8-afec-005056827e51).');
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
