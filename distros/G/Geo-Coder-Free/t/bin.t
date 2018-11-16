#!perl -w

use strict;

use Test::Most tests => 22;

BIN: {
	eval 'use Test::Script';

	if($@) {
		plan skip_all => 'Test::Script required for testing scripts';
	} else {
		SKIP: {
			script_compiles('bin/testcgibin');
			script_compiles('bin/address_lookup');
			if($ENV{AUTHOR_TESTING}) {
				script_runs(['bin/testcgibin', 1]);
				ok(script_stdout_like(qr/\-77\.03/, 'test 1'));
				ok(script_stderr_is('', 'no error output'));

				script_runs(['bin/testcgibin', 2]);
				ok(script_stdout_like(qr/\-77\.01/, 'test 2'));
				ok(script_stderr_is('', 'no error output'));

				script_runs(['bin/testcgibin', 3]);
				ok(script_stdout_like(qr/\-77\.03/, 'test 3'));
				ok(script_stderr_is('', 'no error output'));

				script_runs(['bin/address_lookup', 'Fairfield Road,', 'Broadstairs,', ' Kent,', ' UK']);
				ok(script_stdout_like(qr/51\.35/, 'test 4'));
				ok(script_stderr_is('', 'no error output'));
			} else {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 20);
			}
		}
	}
}
