use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use MARC::Record;
use MARC::Convert::Wikidata::Item;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000750997.mrc')->s);
my $obj = MARC::Convert::Wikidata::Item->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
isa_ok($obj, 'MARC::Convert::Wikidata::Item');

# Test.
eval {
	MARC::Convert::Wikidata::Item->new;
};
is($EVAL_ERROR, "Parameter 'marc_record' is required.\n",
	"Parameter 'marc_record' is required.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Item->new(
		'marc_record' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'marc_record' must be a 'MARC::Record' object.\n",
	"Parameter 'marc_record' must be a 'MARC::Record' object.");
clean();
