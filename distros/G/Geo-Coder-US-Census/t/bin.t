#!perl -w

use strict;

use Test::Most;

BIN: {
	eval 'use Test::Script';
	if($@) {
		plan(skip_all => 'Test::Script required for testing scripts');
	} else {
		plan(tests => 6);
		SKIP: {
			if($ENV{AUTHOR_TESTING}) {
				script_compiles('bin/census');

				if(-e 't/online.enabled') {
					script_runs(['bin/census']);

					ok(script_stdout_like(qr/\-77\.03/, 'test 1'));
					ok(script_stderr_is('', 'no error output'));
				} else {
					diag('Test requires Internet access');
					skip('Test requires Internet access', 5);
				}
			} else {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 6);
			}
		}
	}
}
