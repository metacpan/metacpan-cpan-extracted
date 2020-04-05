use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Always;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
if (exists $ENV{'ERROR_PURE_TYPE'}) {
	delete $ENV{'ERROR_PURE_TYPE'};
}
eval {
	die 'Error.';
};
is($EVAL_ERROR, "Error.\n", 'Simple message in eval. Default TYPE variable.');
clean();

# Test.
eval {
	die 'Error.';
};
my $tmp = $EVAL_ERROR;
eval {
	die $tmp;
};
is($EVAL_ERROR, "Error.\n", 'More evals.');
clean();

# Test.
$Error::Pure::TYPE = undef;
eval {
	die 'Error.';
};
is($EVAL_ERROR, "Error.\n", 'Simple message in eval. Undefined TYPE '.
	'variable.');
clean();

# Test.
$Error::Pure::TYPE = 'Print';
eval {
	die 'Error.';
};
is($EVAL_ERROR, "Error.\n", 'Simple message in eval. Explicit TYPE variable.');
clean();

# Test.
$Error::Pure::TYPE = 'Die';
$ENV{'ERROR_PURE_TYPE'} = 'Error';
eval {
	die 'Error.';
};
is($EVAL_ERROR, "Error.\n", 'Simple message in eval. TYPE in environment '.
	'variable.');
clean();
