use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::MockObject;
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Test::Warn;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000750997.mrc')->s);
my $obj;
warning_like
	{
		$obj = MARC::Convert::Wikidata::Transform->new(
			'marc_record' => MARC::Record->new_from_usmarc($marc_data),
		);
	}
	qr{^Edition number 'Lidové vydání' cannot clean\.},
	"Test of warning about 'Lidové vydání' edition number.",
;
isa_ok($obj, 'MARC::Convert::Wikidata::Transform');

# Test.
eval {
	MARC::Convert::Wikidata::Transform->new;
};
is($EVAL_ERROR, "Parameter 'marc_record' is required.\n",
	"Parameter 'marc_record' is required (not exist).");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Transform->new(
		'marc_record' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'marc_record' must be a MARC::Record object.\n",
	"Parameter 'marc_record' must be a MARC::Record object (not exist).");
clean();

# Test.
my $mock = Test::MockObject->new;
eval {
	MARC::Convert::Wikidata::Transform->new(
		'marc_record' => $mock,
	);
};
is($EVAL_ERROR, "Parameter 'marc_record' must be a MARC::Record object.\n",
	"Parameter 'marc_record' must be a MARC::Record object (another object).");
clean();
