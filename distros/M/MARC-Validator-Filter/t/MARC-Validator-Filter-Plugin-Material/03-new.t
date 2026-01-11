use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Validator::Filter::Plugin::Material;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Filter::Plugin::Material->new;
isa_ok($obj, 'MARC::Validator::Filter::Plugin::Material');

# Test.
eval {
	MARC::Validator::Filter::Plugin::Material->new(
		'bad_param' => 'foo',
	);
};
is($EVAL_ERROR, "Unknown parameter 'bad_param'.\n",
	"Unknown parameter 'bad_param' (foo).");
clean();
