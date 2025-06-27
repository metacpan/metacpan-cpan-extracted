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
my $marc_data = slurp($data->file('cnb000103538.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
my @publishers = @{$ret->publishers};
is(scalar @publishers, 1, 'Get publisher count (1).');
is($publishers[0]->name, decode_utf8('Výtvarná společnost Kruh ve spolupráci s Galerií H v Kostelci nad Černými lesy a Galerií R v Praze'),
	'Zrcadlení: Get publisher name.');
is($publishers[0]->place, 'Praha', 'Zrcadlení: Get publisher place.');
# TODO This is not true
