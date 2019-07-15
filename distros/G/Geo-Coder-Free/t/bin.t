#!perl -w

use strict;

use Test::Most tests => 22;

BIN: {
	SKIP: {
		eval 'use Test::Script';

		if($@) {
			skip('Test::Script required for testing scripts', 22);
		} else {
			script_compiles('bin/testcgibin');
			script_compiles('bin/address_lookup');
			if($ENV{AUTHOR_TESTING}) {
				my $foo;
				script_runs(['bin/testcgibin', 3], { stdout => \$foo });
				diag($foo);

				script_runs(['bin/testcgibin', 1]);
				ok(script_stdout_like(qr/\-77\.03/, 'test 1'));
				ok(script_stderr_is('', 'no error output'));

				script_runs(['bin/testcgibin', 2]);
				ok(script_stdout_like(qr/\-77\.01/, 'test 2'));
				ok(script_stderr_is('', 'no error output'));

				script_runs(['bin/testcgibin', 3]);
				ok(script_stdout_like(qr/\-77\.03/, 'test 3'));
				ok(script_stderr_is('', 'no error output'));

				script_runs(['bin/testcgibin', 4]);
				ok(script_stdout_like(qr/\-77\.03/, 'test 3'));
				ok(script_stderr_is('', 'no error output'));

				script_runs(['bin/address_lookup', 'Fairfield Road,', 'Broadstairs,', ' Kent,', ' UK']);
				ok(script_stdout_like(qr/51\.35/, 'test 5'));
				ok(script_stderr_is('', 'no error output'));
			} else {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 20);
			}
		}
	}
}
