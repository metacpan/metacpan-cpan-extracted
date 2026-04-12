use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::Convert::Wikidata::Item::Periodical;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb002564059.xml')->s);
my $marc_record = MARC::Record->new_from_xml($marc_data, 'UTF-8');
my $transform_obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => $marc_record,
);
my $obj = MARC::Convert::Wikidata::Item::Periodical->new(
	'marc_record' => $marc_record,
	'transform_object' => $transform_obj->object,
);
my $ret = $obj->wikidata_end_time;
is($ret, undef, 'Wikidata end date (undef - 9999 in 008 field).');
