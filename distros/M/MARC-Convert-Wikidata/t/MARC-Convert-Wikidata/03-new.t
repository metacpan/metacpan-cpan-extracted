use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use MARC::Record;
use MARC::Convert::Wikidata;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Warn;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
eval {
	MARC::Convert::Wikidata->new;
};
is($EVAL_ERROR, "Parameter 'marc_record' is required.\n",
	"Parameter 'marc_record' is required.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata->new(
		'marc_record' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'marc_record' must be a 'MARC::Record' object.\n",
	"Parameter 'marc_record' must be a 'MARC::Record' object.");
clean();

# Test.
my $marc_data = slurp($data->file('cnb000750997.mrc')->s);
my $obj;
warning_like
	{
		$obj = MARC::Convert::Wikidata->new(
			# XXX
			'ignore_data_errors' => 1,
			'marc_record' => MARC::Record->new_from_usmarc($marc_data),
		);
	}
	qr{^Edition number 'Lidové vydání' cannot clean\.},
	"Test of warning about 'Lidové vydání' edition number.",
;
isa_ok($obj, 'MARC::Convert::Wikidata');
