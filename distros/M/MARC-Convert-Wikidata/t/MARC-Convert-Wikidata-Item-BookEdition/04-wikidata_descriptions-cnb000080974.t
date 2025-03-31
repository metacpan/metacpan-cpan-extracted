use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::Convert::Wikidata::Item::BookEdition;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000080974.xml')->s);
my $marc_record = MARC::Record->new_from_xml($marc_data, 'UTF-8');
my $transform_obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => $marc_record,
);
my $obj = MARC::Convert::Wikidata::Item::BookEdition->new(
	'marc_record' => $marc_record,
	'transform_object' => $transform_obj->object,
);
my @descriptions = @{$obj->wikidata_descriptions};
is($descriptions[0]->language, 'cs', 'Get first description language (cs).');
my $cs_desc = decode_utf8('české knižní vydání z roku 1994');
is($descriptions[0]->value, $cs_desc, 'Get first description language ('.encode_utf8($cs_desc).').');
is($descriptions[1]->language, 'en', 'Get first description language (en).');
is($descriptions[1]->value, '1994 Czech book edition', 'Get first description language (1994 Czech book edition).');
