use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Leader;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Leader->new;
isa_ok($obj, 'MARC::Leader');

# Test.
eval {
	MARC::Leader->new(
		'verbose' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'verbose' must be a bool (0/1).\n",
	"Parameter 'verbose' must be a bool (0/1) (bad).");
clean();
