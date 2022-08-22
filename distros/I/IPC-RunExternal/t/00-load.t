#!perl

use strict;
use warnings;

use Test::More;
use Const::Fast;
use English qw( -no_match_vars );

if( $OSNAME eq 'MSWin32' ) {
    plan skip_all => 'Skip all tests on Windows';
}

use IPC::RunExternal;

my $version = $IPC::RunExternal::VERSION // '(version N/A)';
diag( "Testing IPC::RunExternal $version, Perl $], $^X" );

const my $EXIT_STATUS_OK      => 1;
const my $EXIT_STATUS_TIMEOUT => 0;
const my $EXIT_STATUS_FAILED  => -1;
const my $TRUE                => 1;
const my $FALSE               => 0;
const my $EMPTY_STR           => q{};
const my $TIMEOUT_3_SECS      => 3;
const my $TIMEOUT_2_SECS      => 2;
const my $TIMEOUT_1_SECS      => 1;
const my $TIMEOUT_0_SECS      => 0;

my $command = $EMPTY_STR;
my $input = $EMPTY_STR;
my $exit_code = 0;
my $stdout = $EMPTY_STR;
my $stderr = $EMPTY_STR;
my $allout = $EMPTY_STR;

	# local $ENV{'PATH'} = q{}; # Testing in tainted mode (-T)
	# local $ENV{'ENV'} = q{}; # Testing in tainted mode (-T)
	# Running these tests requires Test::Exception, not supported!
	#isnt(runexternal(undef, $EMPTY_STR, 3), -1, "Invalid parameter causes failure (command)");
	#isnt(runexternal('date', 1, 3), -1, "Invalid parameter causes failure (input 1)");
	#isnt(runexternal('date', 1, -1), -1, "Invalid parameter causes failure (timeout)");

subtest './non_existing_command' => sub {
	local $ENV{'PATH'} = q{}; # Testing in tainted mode (-T)
	local $ENV{'ENV'} = q{}; # Testing in tainted mode (-T)
	($exit_code, $stdout, $stderr, $allout) = runexternal('./non_existing_command', $EMPTY_STR, $TIMEOUT_2_SECS);
	is($exit_code, $EXIT_STATUS_FAILED,                'non_existing_command Test result failure (1)');
	#is($stdout, q{},                                  'non_existing_command Test result failure (2)');
	#like($stderr, '/.*/',                             'non_existing_command Test result failure (3)'); # The error message is system and shell specific!
	#like($stderr, '/No such file or directory/xmsg', 'qwert Test result failure (4)');
    done_testing();
};

subtest 'echo "Test"' => sub {
	local $ENV{'PATH'} = q{}; # Testing in tainted mode (-T)
	local $ENV{'ENV'} = q{}; # Testing in tainted mode (-T)
	($exit_code, $stdout, $stderr, $allout) = runexternal('echo "Test"', $EMPTY_STR, $TIMEOUT_2_SECS);
	is($exit_code, $EXIT_STATUS_OK,                   'Echo Test result (1)');
	is($stdout, "Test\n",                             'Echo Test result (2)');
	is($stderr, q{},                                   'Echo Test result (3)');
    done_testing();
};

subtest '/usr/bin/wc' => sub {
	local $ENV{'PATH'} = q{}; # Testing in tainted mode (-T)
	local $ENV{'ENV'} = q{}; # Testing in tainted mode (-T)
	($exit_code, $stdout, $stderr, $allout) = runexternal('/usr/bin/wc', 'QWERT', 2);
	is($exit_code, $EXIT_STATUS_OK,                   'Wc Test result (1)');
	#like($stdout, '/.*0.*1.*5.*/',          "Wc Test result (2)");
	like($stdout, '/      0       1       5/',          'Wc Test result (2)'); # Better a regexp. BSD Unix returns an extra prefix whitespace.
	#is($stdout, "      0       1       5\n",          "Wc Test result (2)");
	is($stderr, q{},                                   'Wc Test result (3)');
    done_testing();
};

subtest 'TestRunExternal_01 loop 4 simple' => sub {
	# local $ENV{'PATH'} = q{}; # Testing in tainted mode (-T)
	# local $ENV{'ENV'} = q{}; # Testing in tainted mode (-T)
	($exit_code, $stdout, $stderr, $allout) = runexternal('t/TestRunExternal_01.pl loop 2 simple', $EMPTY_STR, $TIMEOUT_3_SECS);
	is($exit_code, $EXIT_STATUS_OK,                                 'TestRunExternal_01.pl 2 simple result (1)');
	like($stdout, '/STDOUT:2/',          'TestRunExternal_01.pl 2 simple result (2)');
	#like($stdout, '/Going to run for 5 secs. Printing to STDOUT and STDERR./',          "TestRunExternal_01.pl 2 simple result (2)");
	like($stderr, '/STDERR:1/',          'TestRunExternal_01.pl 2 simple result (3)');
	#like($allout, '/STDOUT:2\$STDERR:1/',          "TestRunExternal_01.pl 2 simple result (4)");
    done_testing();
};

subtest 'TestRunExternal_01 loop 10' => sub {
	# local $ENV{'PATH'} = q{}; # Testing in tainted mode (-T)
	# local $ENV{'ENV'} = q{}; # Testing in tainted mode (-T)
	($exit_code, $stdout, $stderr, $allout) = runexternal('t/TestRunExternal_01.pl loop 10', $EMPTY_STR, $TIMEOUT_3_SECS);
	is($exit_code, $EXIT_STATUS_TIMEOUT,                                 'TestRunExternal_01.pl Timeout result (1)');
	#like($stdout, '/.*This program is part of IPC::RunExternal package test suite.*/',          "TestRunExternal_01.pl Timeout result (2)");
	#like($stdout, '/Going to run for 5 secs. Printing to STDOUT and STDERR./',          "TestRunExternal_01.pl Timeout result (2)");
	like($stderr, '/Timeout/',          'TestRunExternal_01.pl Timeout result (3)');
	like($stderr, '/to STDERR/',          'TestRunExternal_01.pl Timeout result (3)');
	like($allout, '/.*Timeout.*/',          'TestRunExternal_01.pl Timeout result (4)');
    done_testing();
};

subtest 'TestRunExternal_01 loop 4 simple' => sub {
	# local $ENV{'PATH'} = q{}; # Testing in tainted mode (-T)
	# local $ENV{'ENV'} = q{}; # Testing in tainted mode (-T)
	($exit_code, $stdout, $stderr, $allout) = runexternal('t/TestRunExternal_01.pl loop 4 simple', $EMPTY_STR, $TIMEOUT_0_SECS,
			{ #print_progress_indicator => $TRUE
			});
	#print ' END PROGRESS...\n';
	is($exit_code, $EXIT_STATUS_OK,      'TestRunExternal_01.pl loop 4 + print_prog_ind No timeout result (1)');
	like($stdout, '/STDOUT:4/',          'TestRunExternal_01.pl loop 4 + print_prog_ind  No timeout result (2)');
	like($stderr, '/STDERR:3/',          'TestRunExternal_01.pl loop 4 + print_prog_ind  No timeout result (3)');
    done_testing();
};

subtest 'TestRunExternal_01 loop 6' => sub {
	# local $ENV{'PATH'} = q{}; # Testing in tainted mode (-T)
	# local $ENV{'ENV'} = q{}; # Testing in tainted mode (-T)
	($exit_code, $stdout, $stderr, $allout) = runexternal('t/TestRunExternal_01.pl loop 6', $EMPTY_STR, $TIMEOUT_1_SECS,
			{ #print_progress_indicator => $TRUE,
				progress_indicator_char => q{#}
			});
	#print ' END PROGRESS...\n';
	is($exit_code, $EXIT_STATUS_TIMEOUT,                                 'TestRunExternal_01.pl loop 6 Timeout + progress_ind # result (1)');
	like($stderr, '/.*Timeout.*/',          'TestRunExternal_01.pl loop 6 Timeout + progress_ind # result (3)');

	is(length($stdout) + length($stderr), length($allout), 'TestRunExternal_01.pl output OK Timeout result (4)');
    done_testing();
};

done_testing();

