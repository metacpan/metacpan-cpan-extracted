use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Leader::Print;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Leader::Print->new;
isa_ok($obj, 'MARC::Leader::Print');

# Test.
eval {
	MARC::Leader::Print->new(
		'lang' => 'xx',
	);
};
is($EVAL_ERROR, "Parameter 'lang' doesn't contain valid ISO 639-1 code.\n",
	"Parameter 'lang' doesn't contain valid ISO 639-1 code (xx).");
clean();
