# Pragmas.
use strict;
use warnings;

# Modules.
use FindBin qw($Bin);
use English qw(-no_match_vars);
use Error::Pure::PrintVar qw(err);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Path to dir with T.pm. And load T.pm.
BEGIN {
	unshift @INC, $Bin;
};
use T;

# Test.
eval {
	err 'Error.';
};
is($EVAL_ERROR, 'Error.'."\n", 'Simple message in eval.');

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
eval {
	T::example;
};
is($EVAL_ERROR, 'Something.'."\n", 'Error from module.');

# Test.
eval {
	err undef;
};
is($EVAL_ERROR, "undef\n", 'Error undefined value.');

# Test.
eval {
	err ();
};
is($EVAL_ERROR, "undef\n", 'Error blank array.');
