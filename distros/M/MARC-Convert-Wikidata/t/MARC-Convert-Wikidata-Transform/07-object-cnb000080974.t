use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000080974.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	# XXX
	'ignore_data_errors' => 1,
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
my $series = $ret->series->[0];
is($series->issn, '0585-5675', 'Mluvený text a jeho syntaktická výstavba: Get ISSN (0585-5675).');
is($series->name, decode_utf8('Studie a práce lingvistické'),
	'Mluvený text a jeho syntaktická výstavba: Get series name (Studie a práce lingvistické).');
is($series->publisher->name, 'Academia',
	'Mluvený text a jeho syntaktická výstavba: Get series publisher name (Academia).');
is($series->publisher->place, 'Praha', 'Mluvený text a jeho syntaktická výstavba: Get series publisher place (Praha).');
is($series->series_ordinal, 27, 'Mluvený text a jeho syntaktická výstavba: Get series ordinal (27).');
