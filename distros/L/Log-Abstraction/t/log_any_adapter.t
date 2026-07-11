#!/usr/bin/env perl
# t/log_any_adapter.t -- Tests for Log::Any::Adapter::Abstraction

use strict;
use warnings;

use Test::Most;
use Test::Needs qw(Log::Any Log::Any::Adapter);

use Log::Abstraction;
use Log::Any::Adapter;
use Log::Any;

# ---------------------------------------------------------------------------
# 1. Basic routing: messages dispatched through the adapter reach the backend
# ---------------------------------------------------------------------------

subtest 'info message routed to array backend via adapter' => sub {
	plan tests => 3;

	my @msgs;
	my $la = Log::Abstraction->new(logger => \@msgs, level => 'debug');
	Log::Any::Adapter->set('Abstraction', instance => $la);

	my $log = Log::Any->get_logger(category => 'TestA');
	$log->info('hello adapter');

	is(scalar(@msgs), 1, 'one message stored');
	is($msgs[0]{level},   'info',          'level is info');
	is($msgs[0]{message}, 'hello adapter', 'message text correct');
};

# ---------------------------------------------------------------------------
# 2. Level mapping: Log::Any 'warning' maps to Log::Abstraction 'warn'
# ---------------------------------------------------------------------------

subtest 'warning level maps to warn' => sub {
	plan tests => 2;

	my @msgs;
	my $la = Log::Abstraction->new(logger => \@msgs, level => 'debug');
	Log::Any::Adapter->set('Abstraction', instance => $la);

	my $log = Log::Any->get_logger(category => 'TestB');
	$log->warning('a warning');

	is(scalar(@msgs), 1, 'one message stored');
	is($msgs[0]{level}, 'warn', 'level stored as warn (not warning)');
};

# ---------------------------------------------------------------------------
# 3. Level mapping: critical/alert/emergency all route to error
# ---------------------------------------------------------------------------

subtest 'critical, alert, emergency all route to error' => sub {
	plan tests => 6;

	for my $la_level (qw(critical alert emergency)) {
		my @msgs;
		my $la = Log::Abstraction->new(logger => \@msgs, level => 'debug');
		Log::Any::Adapter->set('Abstraction', instance => $la);

		my $log = Log::Any->get_logger(category => "Test_$la_level");
		$log->$la_level("$la_level message");

		is(scalar(@msgs), 1, "$la_level produced one message");
		is($msgs[0]{level}, 'error', "$la_level stored as error");
	}
};

# ---------------------------------------------------------------------------
# 4. All nine Log::Any logging levels dispatch without error
# ---------------------------------------------------------------------------

subtest 'all Log::Any logging levels dispatch without error' => sub {
	my @la_levels = qw(trace debug info notice warning error critical alert emergency);
	plan tests => scalar(@la_levels);

	my @msgs;
	my $la = Log::Abstraction->new(logger => \@msgs, level => 'trace');
	Log::Any::Adapter->set('Abstraction', instance => $la);

	my $log = Log::Any->get_logger(category => 'TestAll');
	for my $la_level (@la_levels) {
		lives_ok(sub { $log->$la_level("test $la_level") },
			"$la_level dispatches without error");
	}
};

# ---------------------------------------------------------------------------
# 5. Detection methods (is_*) reflect the Log::Abstraction threshold
# ---------------------------------------------------------------------------

subtest 'is_debug true when level=debug, false when level=warn' => sub {
	plan tests => 4;

	my @msgs;
	my $la_debug = Log::Abstraction->new(logger => \@msgs, level => 'debug');
	Log::Any::Adapter->set('Abstraction', instance => $la_debug);
	my $log = Log::Any->get_logger(category => 'TestIsDebug');
	ok($log->is_debug(),   'is_debug true at debug level');
	ok($log->is_trace(),   'is_trace true at debug level (trace=debug threshold)');

	my $la_warn = Log::Abstraction->new(logger => \@msgs, level => 'warn');
	Log::Any::Adapter->set('Abstraction', instance => $la_warn);
	my $log2 = Log::Any->get_logger(category => 'TestIsWarn');
	ok(!$log2->is_debug(),  'is_debug false at warn level');
	ok(!$log2->is_info(),   'is_info false at warn level');
};

subtest 'is_warning and is_error reflect thresholds' => sub {
	plan tests => 4;

	my @msgs;
	my $la = Log::Abstraction->new(logger => \@msgs, level => 'warn');
	Log::Any::Adapter->set('Abstraction', instance => $la);
	my $log = Log::Any->get_logger(category => 'TestIsWarning');

	ok($log->is_warning(), 'is_warning true at warn level');
	ok($log->is_error(),   'is_error true at warn level');
	ok(!$log->is_info(),   'is_info false at warn level');
	ok(!$log->is_notice(), 'is_notice false at warn level');
};

# ---------------------------------------------------------------------------
# 6. Adapter creation from constructor args (without a pre-built instance)
# ---------------------------------------------------------------------------

subtest 'adapter builds Log::Abstraction from constructor args' => sub {
	plan tests => 2;

	my @msgs;
	Log::Any::Adapter->set('Abstraction', level => 'debug', logger => \@msgs);

	my $log = Log::Any->get_logger(category => 'TestCtor');
	$log->debug('ctor test');

	is(scalar(@msgs), 1, 'one message stored');
	is($msgs[0]{message}, 'ctor test', 'message text correct');
};

# ---------------------------------------------------------------------------
# 7. Threshold: messages below the configured level are dropped
# ---------------------------------------------------------------------------

subtest 'messages below threshold are not stored' => sub {
	plan tests => 1;

	my @msgs;
	my $la = Log::Abstraction->new(logger => \@msgs, level => 'warn');
	Log::Any::Adapter->set('Abstraction', instance => $la);

	my $log = Log::Any->get_logger(category => 'TestThresh');
	$log->debug('should be dropped');
	$log->info('also dropped');

	is(scalar(@msgs), 0, 'debug and info dropped at warn threshold');
};

done_testing();
