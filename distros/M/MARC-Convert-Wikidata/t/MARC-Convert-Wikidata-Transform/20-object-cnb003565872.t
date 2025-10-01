use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb003565872.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
my $cycle = $ret->cycles->[0];
is($cycle->name, decode_utf8('Odkaz Dračích jezdců (ilustrované vydání)'),
	'Eragon: Get cycle name (Odkaz Dračích jezdců (ilustrované vydání)).');
is($cycle->publisher->name, 'Fragment', 'Eragon: Get cycle publisher name (Fragment).');
is($cycle->publisher->place, 'Praha', 'Eragon: Get cycle publisher place (Praha).');
is($cycle->series_ordinal, 1, 'Eragon: Get series ordinal (1).');
