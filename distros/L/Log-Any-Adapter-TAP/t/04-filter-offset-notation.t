#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Log::Any '$log';
use FindBin;
use lib "$FindBin::Bin/lib";
use TestLogging;

$SIG{__DIE__}= $SIG{__WARN__}= sub { diag @_; };

use_ok( 'Log::Any::Adapter', 'TAP' ) or die;

my $buf;

subtest "filter level 'info-1'" => sub {
	Log::Any::Adapter->set('TAP', filter => 'info-1');

	test_log_method($log, @$_) for (
		# method, message, pattern
		[ 'fatal',   'test-fatal',   '', qr/s*# fatal: test-fatal\n/ ],
		[ 'error',   'test-error',   '', qr/s*# error: test-error\n/ ],
		[ 'warning', 'test-warning', '', qr/s*# warning: test-warning\n/ ],
		[ 'notice',  'test-notice',  qr/s*# notice: test-notice\n/, '' ],
		[ 'info',    'test-info',    qr/s*# test-info\n/, '' ],
		[ 'debug',   'test-debug',   '', '' ],
		[ 'trace',   'test-trace',   '', '' ],
	);
};

subtest "filter level 'info+1'" => sub {
	Log::Any::Adapter->set('TAP', filter => 'info+1');

	test_log_method($log, @$_) for (
		# method, message, pattern
		[ 'fatal',   'test-fatal',   '', qr/s*# fatal: test-fatal\n/ ],
		[ 'error',   'test-error',   '', qr/s*# error: test-error\n/ ],
		[ 'warning', 'test-warning', '', qr/s*# warning: test-warning\n/ ],
		[ 'notice',  'test-notice',  '', '' ],
		[ 'info',    'test-info',    '', '' ],
		[ 'debug',   'test-debug',   '', '' ],
		[ 'trace',   'test-trace',   '', '' ],
	);
};

done_testing;
