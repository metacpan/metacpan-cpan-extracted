use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000024035.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	# XXX
	'ignore_data_errors' => 1,
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
my $authors_of_introduction = $ret->authors_of_introduction->[0];
is($authors_of_introduction->name, decode_utf8('Markéta'), 'Terezín v kresbách vězňů: Get author of introduction name.');
is($authors_of_introduction->surname, decode_utf8('Petrášová'), 'Terezín v kresbách vězňů: Get author of introduction surname.');
