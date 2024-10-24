#!perl -w

use strict;

use Test::Most tests => 28;
use Test::Needs { 'Test::Script' => 1.12 };

BIN: {
	SKIP: {
		if(!defined($ENV{'OPENADDR_HOME'})) {
			skip('Set OPENADDR_HOME required for testing scripts', 28);
		} else {
			Test::Script->import();

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
				ok(script_stdout_like(qr/\-77\.03/, 'test 4'));
				ok(script_stderr_is('', 'no error output'));

				if($ENV{'OSM_HOME'} || $ENV{'WHOSONFIRST_HOME'}) {
					script_runs(['bin/address_lookup', 'Fairfield Road,', 'Broadstairs,', ' Kent,', ' UK']);
					ok(script_stdout_like(qr/51\.3/, 'test 5'));
					ok(script_stderr_is('', 'no error output'));
				} else {
					diag('Set OSM_HOME or WHOSONFIRST_HOME for street addresses');
					ok(1);
					ok(1);
					ok(1);
					ok(1);
					ok(1);
				}
			} else {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 26);
			}
		}
	}
}
