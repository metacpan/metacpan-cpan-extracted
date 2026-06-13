use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::Convert::Wikidata::Item::BookEdition;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000442156.xml')->s);
my $marc_record = MARC::Record->new_from_xml($marc_data, 'UTF-8');
my $transform_obj = MARC::Convert::Wikidata::Transform->new(
	'ignore_data_errors' => 1,
	'marc_record' => $marc_record,
);
my $obj = MARC::Convert::Wikidata::Item::BookEdition->new(
	'callback_people' => sub {
		my $people = shift;
		# No process retrieving of QID.
		return;
	},
	'marc_record' => $marc_record,
	'transform_object' => $transform_obj->object,
);
my @authors = $obj->wikidata_authors;
is(@authors, 3, 'Get count of authors without QID (3).');
is($authors[0]->snak->datavalue->value, decode_utf8('Emil Kvítek'), 'Get author name (as string).');
