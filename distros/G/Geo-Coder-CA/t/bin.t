#!perl -w

use strict;

use Test::Most tests => 6;
use Test::Script;

script_compiles('bin/ca');

BIN: {
	SKIP: {
		if(!-e 't/online.enabled') {
			if(!$ENV{RELEASE_TESTING}) {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 5);
			} else {
				diag('Test requires Internet access');
				skip 'Test requires Internet access', 5;
			}
		}

		script_runs(['bin/ca']);

		ok(script_stdout_like(qr/\-77\.03/, 'test 1'));
		ok(script_stderr_is('', 'no error output'));
	}
}
