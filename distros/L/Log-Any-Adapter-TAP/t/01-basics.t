#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Log::Any '$log';
use FindBin;
use lib "$FindBin::Bin/lib";
use TestLogging;

$SIG{__DIE__}= $SIG{__WARN__}= sub { diag @_; };

note "default filter level";

subtest initialization => sub {
	my @warnings;
	local $SIG{__WARN__}= sub { push @warnings, $_[0] };
	use_ok( 'Log::Any::Adapter', 'TAP' ) || BAIL_OUT;
	is( scalar @warnings, 0, "No warnings" )
		or do { diag("got warning: $_") for @warnings };
};

my $buf;

subtest 'Default filter level' => sub {
	test_log_method($log, @$_) for (
		# method, message, pattern
		[ 'fatal',   'test-fatal',   '', qr/\s*# fatal: test-fatal\n/ ],
		[ 'error',   'test-error',   '', qr/\s*# error: test-error\n/ ],
		[ 'warning', 'test-warning', '', qr/\s*# warning: test-warning\n/ ],
		[ 'notice',  'test-notice',  qr/\s*# notice: test-notice\n/, '' ],
		[ 'info',    'test-info',    qr/\s*# test-info\n/, '' ],
		[ 'debug',   'test-debug',   '', '' ],
		[ 'trace',   'test-trace',   '', '' ],
		[ 'info',    "line 1\nline 2",   qr/\s*# line 1\n\s*#\s+line 2\n/, '' ],
		[ 'info',    "line 1\nline 2\n", qr/\s*# line 1\n\s*#\s+line 2\n/, '' ],
	);
};

subtest "filter level 'error'" => sub {
	Log::Any::Adapter->set('TAP', filter => 'error');

	test_log_method($log, @$_) for (
		# method, message, pattern
		[ 'fatal',   'test-fatal',   '', qr/\s*# fatal: test-fatal\n/ ],
		[ 'error',   'test-error',   '', '' ],
		[ 'warning', 'test-warning', '', '' ],
		[ 'notice',  'test-notice',  '', '' ],
		[ 'info',    'test-info',    '', '' ],
		[ 'debug',   'test-debug',   '', '' ],
		[ 'trace',   'test-trace',   '', '' ],
	);
};

subtest "filter level 'trace'" => sub {
	Log::Any::Adapter->set('TAP', filter => 'trace');

	test_log_method($log, @$_) for (
		# method, message, pattern
		[ 'fatal',   'test-fatal',   '', qr/\s*# fatal: test-fatal\n/ ],
		[ 'error',   'test-error',   '', qr/\s*# error: test-error\n/ ],
		[ 'warning', 'test-warning', '', qr/\s*# warning: test-warning\n/ ],
		[ 'notice',  'test-notice',  qr/\s*# notice: test-notice\n/, '' ],
		[ 'info',    'test-info',    qr/\s*# test-info\n/, '' ],
		[ 'debug',   'test-debug',   qr/\s*# debug: test-debug\n/, '' ],
		[ 'trace',   'test-trace',   '', '' ],
	);
};

subtest "filter level 'none'" => sub {
	Log::Any::Adapter->set('TAP', filter => 'none');
	
	test_log_method($log, @$_) for (
		# method, message, pattern
		[ 'fatal',   'test-fatal',   '', qr/\s*# fatal: test-fatal\n/ ],
		[ 'error',   'test-error',   '', qr/\s*# error: test-error\n/ ],
		[ 'warning', 'test-warning', '', qr/\s*# warning: test-warning\n/ ],
		[ 'notice',  'test-notice',  qr/# notice: test-notice\n/, '' ],
		[ 'info',    'test-info',    qr/# test-info\n/, '' ],
		[ 'debug',   'test-debug',   qr/# debug: test-debug\n/, '' ],
		[ 'trace',   'test-trace',   qr/# trace: test-trace\n/, '' ],
	);
};

subtest "filter level 'all'" => sub {
	Log::Any::Adapter->set('TAP', filter => 'all');
	
	test_log_method($log, @$_) for (
		# method, message, pattern
		[ 'emergency', 'test-emerg',   '', '' ],
		[ 'critical',  'test-crit',    '', '' ],
		[ 'fatal',     'test-fatal',   '', '' ],
		[ 'error',     'test-error',   '', '' ],
		[ 'warning',   'test-warning', '', '' ],
		[ 'notice',    'test-notice',  '', '' ],
		[ 'info',      'test-info',    '', '' ],
		[ 'debug',     'test-debug',   '', '' ],
		[ 'trace',     'test-trace',   '', '' ],
	);
};

done_testing;
