use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Validator::Filter::Plugin::RDA;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Filter::Plugin::RDA->new;
isa_ok($obj, 'MARC::Validator::Filter::Plugin::RDA');

# Test.
eval {


	MARC::Validator::Filter::Plugin::RDA->new(
		'bad_param' => 'foo',
	);
};
is($EVAL_ERROR, "Unknown parameter 'bad_param'.\n",
	"Unknown parameter 'bad_param' (foo).");
clean();
