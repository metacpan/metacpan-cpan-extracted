# Pragmas.
use strict;
use warnings;

# Modules.
use Cwd qw(realpath);
use English qw(-no_match_vars);
use Error::Pure::ErrorList qw(err);
use File::Spec::Functions qw(catfile);
use FindBin qw($Bin);
use IO::CaptureOutput qw(capture);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
eval {
	err 'Error.';
};
is($EVAL_ERROR, "Error.\n", 'Simple message in eval.');

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
	err undef;
};
is($EVAL_ERROR, "undef\n", 'Error undefined value.');

# Test.
eval {
	err ();
};
is($EVAL_ERROR, "undef\n", 'Error blank array.');

# Test.
my ($stdout, $stderr);
capture sub {
	system $EXECUTABLE_NAME, realpath(catfile($Bin, '..', 'data', 'ex3.pl'));
} => \$stdout, \$stderr;
is($stdout, '', 'Error in standalone script - stdout.');
like($stderr, qr{^\#Error \[.*?t/data/ex3.pl:11\] Error\.\n$},
	'Error in standalone script - stderr.');

# Test.
($stdout, $stderr) = ('', '');
capture sub {
	system $EXECUTABLE_NAME, realpath(catfile($Bin, '..', 'data', 'ex4.pl'));
} => \$stdout, \$stderr;
is($stdout, '', 'Error with parameter and value in standalone script - stdout.');
like($stderr, qr{^\#Error \[.*?t/data/ex4.pl:11\] Error\.\n$},
	'Error with parameter and value in standalone script - stderr.');
