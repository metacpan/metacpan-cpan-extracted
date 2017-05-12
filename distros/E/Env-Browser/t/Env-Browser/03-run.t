# Pragmas.
use strict;
use warnings;

# Modules.
use Env::Browser qw(run);
use Test::More 'tests' => 6;
use Test::Output;
use Test::NoWarnings;

# Test.
$ENV{'BROWSER'} = 'echo';
stdout_is(
	sub {
		run('URI');
		return;
	},
	"URI\n",
	'Use echo for test.',
);

# Test.
$ENV{'BROWSER'} = 'foo:echo';
stdout_is(
	sub {
		run('URI');
		return;
	},
	"URI\n",
	'Use echo as second command for test.',
);

# Test.
$ENV{'BROWSER'} = 'echo %s';
stdout_is(
	sub {
		run('URI');
		return;
	},
	"URI\n",
	'Use echo for test with %s.',
);

# Test.
$ENV{'BROWSER'} = 'foo:echo %s';
stdout_is(
	sub {
		run('URI');
		return;
	},
	"URI\n",
	'Use echo as second command for test with %s.',
);

# Test.
delete $ENV{'BROWSER'};
stdout_is(
	sub {
		run('URI');
		return;
	},
	'',
	'No environment variable.',
);
