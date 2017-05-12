# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure qw(err);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
if (exists $ENV{'ERROR_PURE_TYPE'}) {
	delete $ENV{'ERROR_PURE_TYPE'};
}
eval {
	err 'Error.';
};
is($EVAL_ERROR, "Error.\n", 'Simple message in eval. Default TYPE variable.');

# Test.
eval {
	err 'Error.';
};
my $tmp = $EVAL_ERROR;
eval {
	err $tmp;
};
is($EVAL_ERROR, "Error.\n", 'More evals.');

# Test.
$Error::Pure::TYPE = undef;
eval {
	err 'Error.';
};
is($EVAL_ERROR, "Error.\n", 'Simple message in eval. Undefined TYPE '.
	'variable.');

# Test.
$Error::Pure::TYPE = 'Print';
eval {
	err 'Error.';
};
is($EVAL_ERROR, "Error.\n", 'Simple message in eval. Explicit TYPE variable.');

# Test.
$Error::Pure::TYPE = 'Die';
$ENV{'ERROR_PURE_TYPE'} = 'Error';
eval {
	err 'Error.';
};
is($EVAL_ERROR, "Error.\n", 'Simple message in eval. TYPE in environment '.
	'variable.');
