# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use File::Object;
use Error::Pure::NoDie qw(err);
use IO::Scalar;
use Test::More 'tests' => 6;

# Path to dir with T.pm. And load T.pm.
BEGIN {
	unshift @INC, File::Object->new->s;
};
use T;

# Test.
eval {
	err 'Error.';
};
is($EVAL_ERROR, "Error.\n", 'Simple message in eval.');

# Test.
eval {
	err 'Error.', 1, 2;
};
is($EVAL_ERROR, "Error.\n", '3 messages in eval.');

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
my $out;
tie *STDOUT, 'IO::Scalar', \$out;
err 'Error';
untie *STDOUT;
is($out, "Error\n", 'Print error instead die.');

# Test.
$out = '';
tie *STDOUT, 'IO::Scalar', \$out;
err 'Error', 1, 2;
untie *STDOUT;
is($out, "Error12\n", 'Print error instead die. Version with more messages.');

# Test.
eval {
	T::example;
};
is($EVAL_ERROR, "Something.\n", 'Error from module.');
