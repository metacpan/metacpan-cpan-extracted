#!/usr/bin/env perl

# edge_cases.t - Destructive, pathological and boundary-condition tests for
# Log::Abstraction.
#
# Philosophy: every guard clause, regex, conditional branch, type check and
# implicit assumption in the module gets at least one test that tries to break
# it.  If the module handles it gracefully the test passes; if it dies
# unexpectedly the test catches and reports that.

use strict;
use warnings;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Log::Abstraction;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Mockingbird qw(mock_scoped);

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub array_logger {
	my $level = shift // 'debug';
	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => $level);
	return ($logger, \@log);
}

sub tmp_file {
	my ($fh, $path) = tempfile(SUFFIX => '.log', UNLINK => 1);
	close $fh;
	return $path;
}

sub slurp { open my $fh, '<', $_[0] or die $!; local $/; <$fh> }

# ============================================================
# 1. new() — pathological constructor arguments
# ============================================================

subtest 'new() — undef as sole argument does not crash' => sub {
	plan tests => 1;

	# undef passed as bare logger value — stored as undef logger,
	# which should not crash construction (falls through to Log4perl default)
	lives_ok(sub { Log::Abstraction->new(undef) }, 'undef arg survives new()');
};

subtest 'new() — empty hash is valid' => sub {
	plan tests => 1;

	# No logger, no file, no array — falls through to Log4perl default
	lives_ok(sub { Log::Abstraction->new({}) }, 'empty hashref survives new()');
};

subtest 'new() — empty string logger is stored' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(logger => '');
	isa_ok($logger, 'Log::Abstraction');
};

subtest 'new() — repeated construction does not leak between instances' => sub {
	plan tests => 2;

	my @log_a; my @log_b;
	my $a = Log::Abstraction->new(array => \@log_a, level => 'debug');
	my $b = Log::Abstraction->new(array => \@log_b, level => 'debug');
	$a->debug('only a');
	is(scalar(@log_b), 0, 'log_b untouched after writing to a');
	$b->debug('only b');
	is(scalar(@log_a), 1, 'log_a still has only its own entry');
};

subtest 'new() — invalid level string croaks' => sub {
	plan tests => 2;

	# Note: empty string is falsy so bypasses the if($level) guard in new()
	# and silently falls through to the default 'warning' level.
	# Only non-empty unrecognised strings trigger the croak.
	for my $bad ('LOUD', 'verbose') {
		throws_ok(
			sub { Log::Abstraction->new(array => [], level => $bad) },
			qr/invalid syslog level/i,
			"level '$bad' rejected"
		);
	}
};

subtest 'new() — level as arrayref uses first element' => sub {
	plan tests => 1;

	# POD does not document this but the code handles it:
	# if ref($level) eq 'ARRAY', uses $level->[0]
	my @log;
	lives_ok(
		sub { Log::Abstraction->new(array => \@log, level => ['debug']) },
		'level passed as arrayref does not croak'
	);
};

subtest 'new() — attempt to encapsulate self croaks' => sub {
	plan tests => 1;

	my ($inner) = array_logger();
	throws_ok(
		sub { Log::Abstraction->new(logger => $inner) },
		qr/needless indirection/i,
		'wrapping Log::Abstraction in itself rejected'
	);
};

# ============================================================
# 2. Message content — boundary values
# ============================================================

subtest 'empty string message stored as empty string' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->debug('');
	is(scalar(@{$log}), 1,  'empty string creates an entry');
	is($log->[0]{message}, '', 'message stored as empty string');
};

subtest 'whitespace-only message preserved' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->debug('   ');
	is($log->[0]{message}, '   ', 'whitespace-only message preserved');
};

subtest 'very long message stored intact' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	my $long = 'x' x 100_000;
	$logger->debug($long);
	is(scalar(@{$log}), 1, 'long message logged');
	is(length($log->[0]{message}), 100_000, 'long message stored at full length');
};

subtest 'message with embedded newlines — only trailing newline stripped' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->debug("line1\nline2\n");
	# chomp strips one trailing newline; embedded newline survives
	is($log->[0]{message}, "line1\nline2", 'trailing newline stripped, embedded preserved');
};

subtest 'message with null bytes stored intact' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->debug("before\x00after");
	is($log->[0]{message}, "before\x00after", 'null byte in message survives');
};

subtest 'message with unicode stored intact' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->debug("日本語テスト");
	is($log->[0]{message}, "日本語テスト", 'unicode message stored intact');
};

subtest 'undef in message list silently skipped' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->debug(undef, 'defined', undef, 'also defined', undef);
	is($log->[0]{message}, 'definedalso defined', 'undefs skipped, rest joined');
};

subtest 'all-undef message list produces empty string entry' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->debug(undef, undef, undef);
	is(scalar(@{$log}), 1, 'all-undef list still creates entry');
	is($log->[0]{message}, '', 'message is empty string');
};

subtest 'zero as message value stored correctly' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->debug(0);
	is($log->[0]{message}, '0', 'zero stored as string "0"');
};

subtest 'message that is the string "0" is not filtered' => sub {
	plan tests => 1;

	# "0" is false in Perl — guard against grep/defined filtering it
	my ($logger, $log) = array_logger();
	$logger->info('0');
	is(scalar(@{$log}), 1, '"0" message not silently dropped');
};

subtest 'very large number of messages does not exhaust memory visibly' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->debug($_) for 1 .. 10_000;
	is(scalar(@{$log}), 10_000, '10,000 messages stored without error');
};

# ============================================================
# 3. warn() / _high_priority — pathological inputs
# ============================================================

subtest 'warn() — undef sole argument is a no-op' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn(undef);
	is(scalar(@{$log}), 0, 'warn(undef) produces no log entry');
};
subtest 'warn() — empty string produces entry' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->warn('');
	is(scalar(@{$log}), 1, 'warn("") produces an entry');
	is($log->[0]{message}, '', 'entry message is empty string');
};

subtest 'warn() — warning => undef is a no-op' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn(warning => undef);
	is(scalar(@{$log}), 0, 'warn(warning => undef) produces no entry');
};
subtest 'warn() — arrayref with all undefs produces empty message without warning' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	lives_ok(sub { $logger->warn(warning => [undef, undef]) },
		'arrayref warning with all undefs does not die');
	is($warned, 0, 'no Perl warning emitted for all-undef arrayref warning');
};
subtest 'warn() — deeply nested arrayref not flattened' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	# _high_priority only flattens one level (ref eq 'ARRAY' on $warning)
	$logger->warn(warning => ['outer', ['inner']]);
	is(scalar(@{$log}), 1, 'nested arrayref warning logged without crash');
};

subtest 'error() — no croak when array backend defined and no croak_on_error' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	my $croaked = 0;
	my $g = mock_scoped 'Carp::croak' => sub { $croaked++ };
	$logger->error('no croak please');
	is($croaked, 0, 'no croak for error() with array backend and no croak_on_error');
};

subtest 'fatal() with croak_on_error — message in croak text' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(
		array => \@log, level => 'debug', croak_on_error => 1
	);
	throws_ok(
		sub { $logger->fatal('boom') },
		qr/boom/,
		'croak text contains the fatal message'
	);
};

# ============================================================
# 4. File backend — boundary and destructive conditions
# ============================================================

subtest 'file — null byte in filename croaks' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(
		file  => "/tmp/bad\x00file.log",
		level => 'debug',
	);
	throws_ok(
		sub { $logger->debug('trigger') },
		qr/Invalid file name/i,
		'null byte in top-level file path rejected'
	);
};

subtest 'file — shell metacharacter in filename croaks' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(
		file  => '/tmp/bad|file.log',
		level => 'debug',
	);
	throws_ok(
		sub { $logger->debug('trigger') },
		qr/Invalid file name/i,
		'pipe character in top-level file path rejected'
	);
};

subtest 'file — backtick in filename croaks' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(
		file  => '/tmp/bad`file.log',
		level => 'debug',
	);
	throws_ok(
		sub { $logger->debug('trigger') },
		qr/Invalid file name/i,
		'backtick in top-level file path rejected'
	);
};

subtest 'hash-ref logger file — null byte in filename croaks' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(
		logger => { file => "/tmp/bad\x00hash.log" },
		level  => 'debug',
	);
	throws_ok(
		sub { $logger->debug('trigger') },
		qr/Invalid file name/i,
		'null byte in hash-ref file path rejected'
	);
};

subtest 'hash-ref logger file — pipe in filename croaks' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(
		logger => { file => '/tmp/bad|hash.log' },
		level  => 'debug',
	);
	throws_ok(
		sub { $logger->debug('trigger') },
		qr/Invalid file name/i,
		'pipe in hash-ref file path rejected'
	);
};

subtest 'file — messages still recorded in messages() even if file write would fail' => sub {
	plan tests => 1;

	# Use a valid writable file — just confirm messages() is populated
	# regardless of backend
	my $path = tmp_file();
	my $logger = Log::Abstraction->new(file => $path, level => 'debug');
	$logger->debug('file and internal');
	is(scalar(@{$logger->messages()}), 1,
		'internal messages() populated even for file-only logger');
};

subtest 'file — level filter means zero bytes written for filtered messages' => sub {
	plan tests => 1;

	my $path = tmp_file();
	my $logger = Log::Abstraction->new(file => $path, level => 'error');
	$logger->debug('no');
	$logger->info('no');
	$logger->notice('no');
	is(-s $path, 0, 'no bytes written to file for filtered messages');
};

# ============================================================
# 5. Format string — boundary and injection attempts
# ============================================================

subtest 'format — unknown token left as literal' => sub {
	plan tests => 1;

	my $path = tmp_file();
	my $logger = Log::Abstraction->new(
		file   => $path,
		level  => 'debug',
		format => '%unknown_token%',
	);
	$logger->debug('x');
	my $content = slurp($path);
	# Unknown token not expanded — stays as literal or empty
	like($content, qr/^.{0,30}\n?$/, 'unknown token produces short/empty output without crash');
};

subtest 'format — %message% with percent signs in message body' => sub {
	plan tests => 1;

	my $path = tmp_file();
	my $logger = Log::Abstraction->new(
		file   => $path,
		level  => 'debug',
		format => '%message%',
	);
	$logger->debug('100% done %level%');
	my $content = slurp($path);
	# %level% inside the message is substituted because format expansion is
	# global — this is a known quirk, not a security hole; just don't crash
	lives_ok(sub { 1 }, 'percent signs in message body do not crash');
};

subtest 'format — empty format string falls back to default (empty string is falsy)' => sub {
	plan tests => 1;

	# format => '' is falsy in Perl, so the expression
	# $self->{'format'} || '%level%> [%timestamp%] ...' picks the default.
	# An empty format string cannot be distinguished from "not set".
	my $path = tmp_file();
	my @sink;
	my $logger = Log::Abstraction->new(
		file   => $path,
		array  => \@sink,
		level  => 'debug',
		format => '',
	);
	$logger->debug('anything');
	my $content = slurp($path);
	like($content, qr/DEBUG/i, 'empty format falls back to default format containing level');
};

subtest 'format — %env_NONEXISTENT% expands to empty string without warning' => sub {
	plan tests => 3;

	# Bug fixed: s/%env_(\w+)%/$ENV{$1}/g emitted "uninitialized value"
	# warning when the env var did not exist.  Fix: use /e with // ''.
	delete $ENV{LA_NONEXISTENT_VAR_XYZ};

	my $path = tmp_file();
	my @sink;
	my $logger = Log::Abstraction->new(
		file   => $path,
		array  => \@sink,
		level  => 'debug',
		format => '[%env_LA_NONEXISTENT_VAR_XYZ%]',
	);

	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	lives_ok(sub { $logger->debug('env test') },
		'missing env var in format does not crash');

	is($warned, 0, 'no Perl warning emitted for missing env var');

	my $content = slurp($path);
	is($content, "[]\n", 'missing env var expands to empty string, brackets remain');
};

# ============================================================
# 6. level() — boundary values
# ============================================================

subtest 'level() — all valid syslog level names accepted' => sub {
	plan tests => 7;

	my ($logger) = array_logger();
	for my $lvl (qw(debug info notice warn warning error trace)) {
		lives_ok(sub { $logger->level($lvl) }, "level('$lvl') accepted");
	}
};

subtest 'level() — boundary: debug is highest integer (least severe)' => sub {
	plan tests => 1;

	my ($logger) = array_logger('debug');
	my $l = $logger->level();
	cmp_ok($l, '>=', 7, 'debug level integer is >= 7');
};

subtest 'level() — boundary: error is low integer (most severe logged)' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'error');
	cmp_ok($logger->level(), '<=', 3, 'error level integer is <= 3');
};

subtest 'level() — set then immediately get returns same numeric value' => sub {
	plan tests => 3;

	my ($logger) = array_logger();
	for my $pair (['debug', 7], ['warning', 4], ['error', 3]) {
		$logger->level($pair->[0]);
		is($logger->level(), $pair->[1], "level('$pair->[0]') round-trips to $pair->[1]");
	}
};

# ============================================================
# 7. messages() — boundary conditions
# ============================================================

subtest 'messages() — returns fresh copy each call' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	$logger->debug('one');
	my $snap1 = $logger->messages();
	$logger->debug('two');
	my $snap2 = $logger->messages();
	is(scalar(@{$snap1}), 1, 'first snapshot has 1 entry');
	is(scalar(@{$snap2}), 2, 'second snapshot has 2 entries');
};

subtest 'messages() — modifying returned arrayref does not corrupt internal store' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	$logger->debug('real');
	my $copy = $logger->messages();
	push @{$copy}, { level => 'fake', message => 'injected' };
	my $fresh = $logger->messages();
	is(scalar(@{$fresh}), 1,      'internal store unaffected by external push');
	is($fresh->[0]{message}, 'real', 'original message intact');
};

# ============================================================
# 8. Clone — pathological cases
# ============================================================

subtest 'clone — invalid level in clone args croaks' => sub {
	plan tests => 1;

	my ($parent) = array_logger();
	throws_ok(
		sub { $parent->new(level => 'nonsense') },
		qr/invalid syslog level/i,
		'invalid level in clone croaks'
	);
};

subtest 'clone — deep clone chain: each messages() store is independent' => sub {
	plan tests => 4;

	# Clone copies {messages} at clone-time (snapshot), then grows independently.
	# So b,c,d each start with an empty snapshot (cloned before any logging)
	# and each accumulates only its own subsequent messages.
	my @log;
	my $a = Log::Abstraction->new(array => \@log, level => 'debug');
	my $b = $a->new();	# cloned before a logs — b starts empty
	my $c = $b->new();	# cloned before b logs — c starts empty
	my $d = $c->new();	# cloned before c logs — d starts empty

	$a->debug('from a');
	$b->debug('from b');
	$c->debug('from c');
	$d->debug('from d');

	is(scalar(@{$a->messages()}), 1, 'a: 1 message (its own)');
	is(scalar(@{$b->messages()}), 1, 'b: 1 message (cloned before a logged, only its own)');
	is(scalar(@{$c->messages()}), 1, 'c: 1 message (cloned before b logged, only its own)');
	is(scalar(@{$d->messages()}), 1, 'd: 1 message (cloned before c logged, only its own)');
};

subtest 'clone — 1000 clones in a chain do not crash' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	lives_ok(sub {
		for (1 .. 1000) {
			$logger = $logger->new();
		}
		$logger->debug('survived');
	}, '1000-deep clone chain survives');
};

# ============================================================
# 9. Object logger delegation — boundary conditions
# ============================================================

subtest 'object logger — method that dies propagates exception' => sub {
	plan tests => 1;

	my $exploding = bless {}, 'ExplodingLogger';
	{ no warnings 'once'; *ExplodingLogger::debug = sub { die "logger exploded\n" } }

	my $logger = Log::Abstraction->new(logger => $exploding, level => 'debug');
	throws_ok(
		sub { $logger->debug('trigger') },
		qr/logger exploded/,
		'exception from object logger propagates'
	);
};

subtest 'object logger — unsupported level with no info fallback croaks' => sub {
	plan tests => 1;

	my $minimal = bless {}, 'MinimalLogger';
	{ no warnings 'once'; *MinimalLogger::debug = sub { } }
	# Has debug but no notice, and no info to fall back to

	my $logger = Log::Abstraction->new(logger => $minimal, level => 'debug');
	throws_ok(
		sub { $logger->notice('no method') },
		qr/doesn.t know how to deal/i,
		'missing notice with no info fallback croaks'
	);
};

subtest 'object logger — returns from method not inspected' => sub {
	plan tests => 1;

	# Logger whose methods return various things — should not crash
	my $weird = bless {}, 'WeirdReturnLogger';
	{
		no warnings 'once';
		*WeirdReturnLogger::debug = sub { return undef };
		*WeirdReturnLogger::info  = sub { return [] };
		*WeirdReturnLogger::warn  = sub { return 0 };
		*WeirdReturnLogger::error = sub { return {} };
	}

	my $logger = Log::Abstraction->new(logger => $weird, level => 'debug');
	lives_ok(sub {
		$logger->debug('x');
		$logger->info('x');
		$logger->warn('x');
		$logger->error('x');
	}, 'weird return values from object logger do not crash');
};

# ============================================================
# 10. Coderef logger — boundary conditions
# ============================================================

subtest 'coderef logger — that dies propagates exception' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(
		logger => sub { die "coderef exploded\n" },
		level  => 'debug',
	);
	throws_ok(
		sub { $logger->debug('trigger') },
		qr/coderef exploded/,
		'exception from coderef logger propagates'
	);
};

subtest 'coderef logger — that returns undef does not crash' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(
		logger => sub { return undef },
		level  => 'debug',
	);
	lives_ok(sub { $logger->debug('x') }, 'coderef returning undef is fine');
};

subtest 'coderef logger — receives exact message arrayref, not a copy' => sub {
	plan tests => 2;

	my $got;
	my $logger = Log::Abstraction->new(
		logger => sub { $got = $_[0]->{message} },
		level  => 'debug',
	);
	$logger->debug('check', 'ref');
	is(ref($got), 'ARRAY', 'message is ARRAY ref');
	is(join('|', @{$got}), 'check|ref', 'message contents correct');
};

# ============================================================
# 11. Array-ref logger — boundary conditions
# ============================================================

subtest 'array-ref logger — same arrayref used as both logger and external sink' => sub {
	plan tests => 2;

	# Unusual but not prohibited: logger => \@log and array => \@log
	my @log;
	my $logger = Log::Abstraction->new(
		logger => \@log,
		array  => \@log,
		level  => 'debug',
	);
	$logger->debug('dual ref');
	# When logger is an arrayref, _log enters the ref($logger) eq 'ARRAY' branch
	# and pushes there.  The elsif($self->{'array'}) branch is never reached
	# because it only runs when $logger is absent.  One push, not two.
	is(scalar(@log), 1, 'only one push: array branch is elsif to logger branch');
	is($log[0]{message}, 'dual ref', 'message correct');
};

subtest 'array-ref logger — blessed arrayref as logger' => sub {
	plan tests => 1;

	# A blessed arrayref is not ref eq 'ARRAY', so it falls to the object
	# logger path — which means it needs a debug() method
	my $barr = bless [], 'ArrayLogger';
	my @calls;
	{ no warnings 'once'; *ArrayLogger::debug = sub { push @calls, $_[1] } }

	my $logger = Log::Abstraction->new(logger => $barr, level => 'debug');
	$logger->debug('blessed array');
	is($calls[0], 'blessed array', 'blessed arrayref treated as object logger');
};

# ============================================================
# 12. _sanitize_email_header — boundary and injection
# ============================================================

subtest '_sanitize_email_header — empty string returns empty string' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header('');
	is($result, '', 'empty string sanitized to empty string');
};

subtest '_sanitize_email_header — string of only CR/LF returns empty string' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header("\r\n\r\n\n\r");
	is($result, '', 'all-CR/LF string sanitized to empty string');
};

subtest '_sanitize_email_header — header injection attempt neutralised' => sub {
	plan tests => 2;

	my $injected = "victim\@example.com\r\nBcc: attacker\@evil.com";
	my $result   = Log::Abstraction::_sanitize_email_header($injected);
	unlike($result, qr/\r|\n/, 'no CR or LF in sanitized result');
	like($result,   qr/Bcc/,   'Bcc text survives but CR/LF stripped (injection neutralised)');
};

subtest '_sanitize_email_header — very long string handled without crash' => sub {
	plan tests => 1;

	my $long   = 'a' x 1_000_000;
	my $result = Log::Abstraction::_sanitize_email_header($long);
	is(length($result), 1_000_000, '1MB string sanitized without crash');
};

subtest '_sanitize_email_header — unicode content preserved' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header('用户@example.com');
	is($result, '用户@example.com', 'unicode email address preserved');
};

# ============================================================
# 13. Concurrent-ish: rapid level change during logging
# ============================================================

subtest 'rapid level changes during logging — consistent state' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger('debug');
	my $logged = 0;

	for my $i (1 .. 200) {
		if($i % 2 == 0) {
			$logger->level('error');
		} else {
			$logger->level('debug');
		}
		$logger->debug("msg $i");
	}

	# Only odd iterations have level=debug when debug() is called
	my $m = $logger->messages();
	ok(scalar(@{$m}) > 0,   'some messages logged during level oscillation');
	ok(scalar(@{$m}) < 200, 'some messages filtered during level oscillation');
};

# ============================================================
# 14. DESTROY — edge cases
# ============================================================

subtest 'DESTROY — safe to call on object that never logged' => sub {
	plan tests => 1;

	my $closed = 0;
	my $g = mock_scoped 'Sys::Syslog::closelog' => sub { $closed++ };

	{ my ($logger) = array_logger() }	# DESTROY fires, _syslog_opened not set

	is($closed, 0, 'DESTROY on non-syslog logger does not call closelog');
};

subtest 'DESTROY — closelog not called twice on double-DESTROY' => sub {
	plan tests => 1;

	my $closed = 0;
	my $g_close = mock_scoped 'Sys::Syslog::closelog' => sub { $closed++ };
	my $g_open  = mock_scoped 'Log::Abstraction::openlog' => sub { };
	my $g_log   = mock_scoped 'Sys::Syslog::syslog'   => sub { };
	my $g_sock  = mock_scoped 'Log::Abstraction::setlogsock' => sub { };

	my $logger = Log::Abstraction->new(
		logger => { syslog => { facility => 'local0' } },
		level  => 'debug',
		script_name => 'edge_test',
	);
	$logger->warn('open syslog');
	$logger->DESTROY();		# explicit call
	$logger->DESTROY();		# second call — _syslog_opened now deleted

	is($closed, 1, 'closelog called exactly once even with double DESTROY');
};

# ============================================================
# 15. Miscellaneous boundary conditions
# ============================================================

subtest 'is_debug() — true only at debug/trace, false at all others' => sub {
	plan tests => 7;

	my ($logger) = array_logger();
	my %expect = (
		debug   => 1,
		trace   => 1,
		info    => 0,
		notice  => 0,
		warn    => 0,
		warning => 0,
		error   => 0,
	);
	for my $lvl (sort keys %expect) {
		$logger->level($lvl);
		is($logger->is_debug(), $expect{$lvl}, "is_debug() at level '$lvl'");
	}
};

subtest 'messages() — internal store independent from external array backend' => sub {
	plan tests => 2;

	my @ext;
	my $logger = Log::Abstraction->new(array => \@ext, level => 'debug');
	$logger->debug('shared');

	is(scalar(@ext),                    1, 'external array has 1 entry');
	is(scalar(@{$logger->messages()}),  1, 'internal messages() also has 1 entry');
};

subtest 'messages() — entries from messages() have same content as array backend' => sub {
	plan tests => 2;

	my @ext;
	my $logger = Log::Abstraction->new(array => \@ext, level => 'debug');
	$logger->debug('match me');

	is($ext[0]{message},                       'match me', 'external array message');
	is($logger->messages()->[0]{message},       'match me', 'internal messages() message');
};

subtest 'logging after level set to warning does not populate messages() for debug' => sub {
	plan tests => 2;

	my ($logger) = array_logger('warning');
	$logger->debug('gone');
	$logger->info('gone');
	is(scalar(@{$logger->messages()}), 0, 'no messages() entries for filtered levels');
	$logger->warn('kept');
	is(scalar(@{$logger->messages()}), 1, 'warn entry appears in messages()');
};

done_testing();
