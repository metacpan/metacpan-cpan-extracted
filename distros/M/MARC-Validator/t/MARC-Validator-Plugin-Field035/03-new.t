use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Validator::Plugin::Field035;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field035->new;
isa_ok($obj, 'MARC::Validator::Plugin::Field035');

# Test.
eval {
	MARC::Validator::Plugin::Field035->new(
		'debug' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'debug' must be a bool (0/1).\n",
	"Parameter 'debug' must be a bool (0/1) (bad).");
clean();

# Test.
eval {
	MARC::Validator::Plugin::Field035->new(
		'struct' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'struct' isn't hash reference.\n",
	"Parameter 'struct' isn't hash reference (bad).");
clean();
