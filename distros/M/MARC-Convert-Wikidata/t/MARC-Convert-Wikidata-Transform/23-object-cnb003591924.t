use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Warn;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb003591924.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
is($ret->publication_date, 2024, 'Tajný život nenarodeného dieťaťa: Get publication date (2024).');
is($ret->start_time, undef, 'Tajný život nenarodeného dieťaťa: Get start time (undef).');
is($ret->end_time, undef, 'Tajný život nenarodeného dieťaťa: Get end time (undef).');
