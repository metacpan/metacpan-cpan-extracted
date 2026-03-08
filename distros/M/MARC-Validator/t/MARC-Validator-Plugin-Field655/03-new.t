use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Validator::Plugin::Field655;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field655->new;
isa_ok($obj, 'MARC::Validator::Plugin::Field655');

# Test.
eval {
	MARC::Validator::Plugin::Field655->new(
		'debug' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'debug' must be a bool (0/1).\n",
	"Parameter 'debug' must be a bool (0/1) (bad).");
clean();
