use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Warn;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000750575.xml')->s);
my $obj;
warning_like
	{
		$obj = MARC::Convert::Wikidata::Transform->new(
			'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
		);
	}
	qr{Edition number 'Vydání 6\. a 4\. nezměněné' cannot clean\.},
	"Test of warning about edition number.",
;
ok(1, 'TODO Preparation for test of Field 700.');
