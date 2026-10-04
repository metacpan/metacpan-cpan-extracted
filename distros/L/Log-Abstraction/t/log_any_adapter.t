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
# 3. Level mapping: critical/alert/emergency keep their own levels
# ---------------------------------------------------------------------------

subtest 'critical, alert, emergency keep their own levels' => sub {
	plan tests => 8;

	for my $la_level (qw(critical alert emergency)) {
		my @msgs;
		my $la = Log::Abstraction->new(logger => \@msgs, level => 'debug');
		Log::Any::Adapter->set('Abstraction', instance => $la);

		my $log = Log::Any->get_logger(category => "Test_$la_level");
		$log->$la_level("$la_level message");

		is(scalar(@msgs), 1, "$la_level produced one message");
		is($msgs[0]{level}, $la_level, "$la_level stored as $la_level");
	}

	my $la = Log::Abstraction->new(logger => [], level => 'alert');
	Log::Any::Adapter->set('Abstraction', instance => $la);
	my $log = Log::Any->get_logger(category => 'Test_is_high');
	ok(!$log->is_critical() && $log->is_alert() && $log->is_emergency(),
		'is_critical/is_alert/is_emergency have distinct thresholds');
	ok(!$log->is_error(), 'is_error false at alert');
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

# ---------------------------------------------------------------------------
# 8. file/line reported to the backend is the caller's, not Log::Any's
# ---------------------------------------------------------------------------

subtest 'file and line point at the code calling Log::Any' => sub {
	plan tests => 4;

	my @calls;
	my $la = Log::Abstraction->new(logger => sub { push @calls, $_[0] }, level => 'debug');
	Log::Any::Adapter->set('Abstraction', instance => $la);

	my $log = Log::Any->get_logger(category => 'TestCaller');
	$log->info('where am I'); my $info_line = __LINE__;
	$log->warning('and now'); my $warn_line = __LINE__;

	is($calls[0]{file}, __FILE__,  'info: file is this test');
	is($calls[0]{line}, $info_line, 'info: line is the $log->info call');
	is($calls[1]{file}, __FILE__,  'warning: file is this test');
	is($calls[1]{line}, $warn_line, 'warning: line is the $log->warning call');
};

# ---------------------------------------------------------------------------
# 9. A non-Log::Abstraction 'instance' is an error, not a silent fallback
# ---------------------------------------------------------------------------

subtest 'instance must be a Log::Abstraction object' => sub {
	plan tests => 1;

	throws_ok(
		sub {
			Log::Any::Adapter->set('Abstraction', instance => { not => 'a logger' });
			Log::Any->get_logger(category => 'TestBadInstance')->info('x');
		},
		qr/instance must be a Log::Abstraction object/,
		'hashref instance croaks',
	);
};

# ---------------------------------------------------------------------------
# 10. carp_on_warn/croak_on_error are forwarded; logging never dies
# ---------------------------------------------------------------------------

subtest 'croak_on_error is forwarded but turned into a carp' => sub {
	plan tests => 3;

	my @msgs;
	my @carps;
	local $SIG{__WARN__} = sub { push @carps, $_[0] };

	Log::Any::Adapter->set('Abstraction',
		logger => \@msgs, level => 'debug', croak_on_error => 1, carp_on_warn => 1,
	);
	my $log = Log::Any->get_logger(category => 'TestNoDie');

	lives_ok(sub { $log->error('bad thing') }, 'error() through Log::Any does not die');
	like(join('', @carps), qr/bad thing/, 'the croak was turned into a carp');
	is($msgs[0]{message}, 'bad thing', 'message still logged');
};

done_testing();
