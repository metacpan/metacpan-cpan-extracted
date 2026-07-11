#!/usr/bin/env perl
# t/caller_depth.t -- Verify that file/line in log callbacks resolve to the
# caller's source location for ALL log levels, including warn() and error().
#
# Before 0.33, the extra _high_priority stack frame for warn/error caused
# file/line to resolve to the module's internal dispatch, not user code.

use strict;
use warnings;

use Test::Most;
use Log::Abstraction;

# ---------------------------------------------------------------------------
# Helper: capture one CODE-ref callback, return the args hashref.
# ---------------------------------------------------------------------------
sub capture_one {
	my ($level, @msg_args) = @_;
	my $captured;
	my $logger = Log::Abstraction->new(
		level  => 'trace',
		logger => sub { $captured = $_[0] },
	);
	$logger->$level(@msg_args);
	return $captured;
}

# ---------------------------------------------------------------------------
# 1. trace/debug/info/notice: file/line should point to THIS test file.
# ---------------------------------------------------------------------------
subtest 'trace file/line resolves to caller, not module internals' => sub {
	plan tests => 2;
	my $args = capture_one('trace', 'test message');
	like($args->{file}, qr/caller_depth\.t$/,
		'file points to test file, not Abstraction.pm');
	cmp_ok($args->{line}, '>', 0, 'line is a positive integer');
};

subtest 'debug file/line resolves to caller' => sub {
	plan tests => 1;
	my $args = capture_one('debug', 'test message');
	like($args->{file}, qr/caller_depth\.t$/,
		'file points to test file for debug');
};

subtest 'info file/line resolves to caller' => sub {
	plan tests => 1;
	my $args = capture_one('info', 'test message');
	like($args->{file}, qr/caller_depth\.t$/,
		'file points to test file for info');
};

subtest 'notice file/line resolves to caller' => sub {
	plan tests => 1;
	my $args = capture_one('notice', 'test message');
	like($args->{file}, qr/caller_depth\.t$/,
		'file points to test file for notice');
};

# ---------------------------------------------------------------------------
# 2. warn/error: these go through _high_priority — used to be wrong pre-0.33
# ---------------------------------------------------------------------------
subtest 'warn file/line resolves to caller (not _high_priority frame)' => sub {
	plan tests => 2;
	my $args = capture_one('warn', 'test warning');
	like($args->{file}, qr/caller_depth\.t$/,
		'file points to test file for warn, not Abstraction.pm');
	unlike($args->{file}, qr/Abstraction\.pm$/,
		'file is NOT the module itself');
};

subtest 'error file/line resolves to caller (not _high_priority frame)' => sub {
	plan tests => 2;
	my @log;
	my $logger = Log::Abstraction->new(
		level  => 'trace',
		logger => sub { push @log, $_[0] },
	);
	$logger->error('test error');
	my $args = $log[0];
	like($args->{file}, qr/caller_depth\.t$/,
		'file points to test file for error, not Abstraction.pm');
	unlike($args->{file}, qr/Abstraction\.pm$/,
		'file is NOT the module itself');
};

# ---------------------------------------------------------------------------
# 3. fatal (synonym for error) should also resolve correctly.
# ---------------------------------------------------------------------------
subtest 'fatal file/line resolves to caller' => sub {
	plan tests => 1;
	my @log;
	my $logger = Log::Abstraction->new(
		level  => 'trace',
		logger => sub { push @log, $_[0] },
	);
	$logger->fatal('test fatal');
	like($log[0]->{file}, qr/caller_depth\.t$/,
		'file points to test file for fatal');
};

done_testing();
