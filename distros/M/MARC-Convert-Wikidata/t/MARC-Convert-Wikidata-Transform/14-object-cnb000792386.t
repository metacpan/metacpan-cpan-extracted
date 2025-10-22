use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000792386.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
my @series = @{$ret->series};
is($series[0]->name, 'Pantheon', 'Get series name (Pantheon).');
is($series[0]->series_ordinal, 70, 'Get series ordinal (70).');
# XXX Bad name
is($series[1]->name, decode_utf8('Spisů svazek 9. / J.W. Goethe'),
	'Get series name (Spisů svazek 9. / J.W. Goethe).');
