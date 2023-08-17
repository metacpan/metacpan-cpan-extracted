use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(realpath);
use English qw(-no_match_vars);
use Error::Pure::JSON qw(err);
use File::Spec::Functions qw(catfile);
use FindBin qw($Bin);
use JSON qw(decode_json);
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
my ($stdout, $stderr) = capture sub {
	system $EXECUTABLE_NAME, realpath(catfile($Bin, '..', 'data', 'ex1.pl'));
};
is($stdout, '', 'Error in standalone script - stdout.');
my $ret_struct = decode_json($stderr);
$ret_struct->[0]->{'stack'}->[0]->{'prog'} =~ s/.*?(t\/data\/ex1\.pl)$/$1/ms;
is_deeply(
	$ret_struct,
	[
		{
			'msg' => ['Error.'],
			'stack' => [{
				'args' => "('Error.')",
				'class' => 'main',
				'line' => 9,
				'prog' => 't/data/ex1.pl',
				'sub' => 'err',
			}],
		},
	],
	'Error in standalone script - stderr. Decoded from JSON.',
);

# Test.
($stdout, $stderr) = capture sub {
	system $EXECUTABLE_NAME, realpath(catfile($Bin, '..', 'data', 'ex2.pl'));
};
is($stdout, '', 'Error with parameter and value in standalone script - stdout.');
$ret_struct = decode_json($stderr);
$ret_struct->[0]->{'stack'}->[0]->{'prog'} =~ s/.*?(t\/data\/ex2\.pl)$/$1/ms;
is_deeply(
	$ret_struct,
	[
		{
			'msg' => [
				'Error.',
				'Parameter',
				'Value',
			],
			'stack' => [{
				'args' => "('Error.', 'Parameter', 'Value')",
				'class' => 'main',
				'line' => 9,
				'prog' => 't/data/ex2.pl',
				'sub' => 'err',
			}],
		},
	],
	'Error with parameter and value in standalone - stderr. Decoded '.
	'from JSON.',
);
