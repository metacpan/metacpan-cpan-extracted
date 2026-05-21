#!/usr/bin/env perl

# function.t - White-box function tests for Log::Abstraction
# Tests every public and internal method as a standalone function.
#
# Strategy: let all real modules load normally (they are installed).
# Use Test::Mockingbird::mock_scoped to intercept specific outbound calls
# (Carp::carp, Carp::croak, Sys::Syslog::closelog, etc.) only where a
# subtest needs to observe or suppress them.  No stub packages needed.

use strict;
use warnings;
use Log::Abstraction;
use Test::Most;
use Test::Mockingbird qw(mock_scoped);

# ---------------------------------------------------------------------------
# Helper — build a logger that writes to an in-memory array ref
# ---------------------------------------------------------------------------
sub array_logger {
	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	return ($logger, \@log);
}

# ============================================================
# 1. new() — basic construction
# ============================================================
subtest 'new() — scalar logger arg' => sub {
	plan tests => 3;

	my $logger = Log::Abstraction->new('somefile.log');
	ok(defined $logger, 'object created');
	isa_ok($logger, 'Log::Abstraction');
	is($logger->{logger}, 'somefile.log', 'logger attribute stored');
};

subtest 'new() — hash args' => sub {
	plan tests => 3;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	ok(defined $logger, 'object created');
	isa_ok($logger, 'Log::Abstraction');
	is(ref($logger->{array}), 'ARRAY', 'array attribute is ARRAY ref');
};

subtest 'new() — hashref arg' => sub {
	plan tests => 2;

	my @log;
	my $logger = Log::Abstraction->new({ array => \@log, level => 'info' });
	ok(defined $logger, 'object created from hashref');
	isa_ok($logger, 'Log::Abstraction');
};

subtest 'new() — default level is warning' => sub {
	plan tests => 1;

	# Default level stored as integer 4 (warning)
	my $logger = Log::Abstraction->new('somefile.log');
	is($logger->{level}, 4, 'default level integer is 4 (warning)');
};

subtest 'new() — explicit level stored as integer' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	is($logger->{level}, 7, 'debug level stored as integer 7');
};

subtest 'new() — invalid level croaks' => sub {
	plan tests => 1;

	throws_ok(
		sub { Log::Abstraction->new(array => [], level => 'bogus') },
		qr/invalid syslog level/i,
		'invalid level causes croak'
	);
};

subtest 'new() — croaks when encapsulating self' => sub {
	plan tests => 1;

	my @log;
	my $inner = Log::Abstraction->new(array => \@log, level => 'debug');
	throws_ok(
		sub { Log::Abstraction->new(logger => $inner) },
		qr/needless indirection/i,
		'encapsulating Log::Abstraction croaks'
	);
};

subtest 'new() — clone with no args' => sub {
	plan tests => 4;

	my @log;
	my $orig  = Log::Abstraction->new(array => \@log, level => 'debug');
	my $clone = $orig->new();
	isa_ok($clone, 'Log::Abstraction');
	isnt($clone, $orig, 'clone is a different object');
	is($clone->{level}, $orig->{level}, 'clone inherits level');
	isnt($clone->{messages}, $orig->{messages}, 'messages array is a deep copy');
};

subtest 'new() — clone with overrides' => sub {
	plan tests => 2;

	my @log;
	my $orig  = Log::Abstraction->new(array => \@log, level => 'debug');
	my $clone = $orig->new(level => 'info');
	is($clone->{level}, 6, 'clone overrides level to info (6)');
	is($orig->{level},  7, 'original level unchanged');
};

subtest 'new() — messages initialised as empty arrayref' => sub {
	plan tests => 2;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	is(ref($logger->{messages}), 'ARRAY', 'messages is ARRAY ref');
	is(scalar(@{$logger->{messages}}), 0, 'messages starts empty');
};

# ============================================================
# 2. _sanitize_email_header()  (internal — call via full name)
# ============================================================
subtest '_sanitize_email_header() — undef input returns undef' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header(undef);
	ok(!defined($result), 'undef input returns undef');
};

subtest '_sanitize_email_header() — strips LF' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header("foo\nbar");
	is($result, 'foobar', 'LF stripped');
};

subtest '_sanitize_email_header() — strips CR' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header("foo\rbar");
	is($result, 'foobar', 'CR stripped');
};

subtest '_sanitize_email_header() — strips CRLF' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header("foo\r\nbar");
	is($result, 'foobar', 'CRLF stripped');
};

subtest '_sanitize_email_header() — clean string unchanged' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header('user@example.com');
	is($result, 'user@example.com', 'clean value returned unchanged');
};

subtest '_sanitize_email_header() — multiple injections all stripped' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header("a\r\nb\nc\rd");
	is($result, 'abcd', 'all CR/LF characters stripped');
};

# ============================================================
# 3. _log() — private method enforcement
# ============================================================
subtest '_log() — croaks when called from outside the package' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	throws_ok(
		sub { $logger->_log('debug', 'msg') },
		qr/Illegal Operation.*private/i,
		'_log croaks when called from outside Log::Abstraction'
	);
};

# ============================================================
# 4. level() — getter / setter
# ============================================================
subtest 'level() — getter returns integer' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	my $l = $logger->level();
	ok(defined($l) && $l =~ /^\d+$/, 'level() returns an integer');
};

subtest 'level() — setter updates value' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->level('info');
	is($logger->{level}, 6, 'level updated to 6 (info)');
};

subtest 'level() — setter with invalid value warns and returns undef' => sub {
	plan tests => 2;

	my ($logger)  = array_logger();
	my $orig      = $logger->level();
	my $warned    = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $warned++ };
	my $result = $logger->level('nonsense');
	ok($warned,        'Carp::carp called for invalid level');
	ok(!defined($result), 'undef returned for invalid level');
};

# ============================================================
# 5. is_debug()
# ============================================================
subtest 'is_debug() — true when level is debug' => sub {
	plan tests => 1;

	my ($logger) = array_logger();	# constructed with level => 'debug'
	is($logger->is_debug(), 1, 'is_debug true at debug level');
};

subtest 'is_debug() — false when level is warning' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'warning');
	is($logger->is_debug(), 0, 'is_debug false at warning level');
};

subtest 'is_debug() — false when level is error' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'error');
	is($logger->is_debug(), 0, 'is_debug false at error level');
};

# ============================================================
# 6. messages()
# ============================================================
subtest 'messages() — returns empty arrayref initially' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	my $m = $logger->messages();
	is(ref($m), 'ARRAY', 'messages() returns ARRAY ref');
	is(scalar(@{$m}), 0, 'messages() is empty initially');
};

subtest 'messages() — accumulates logged messages' => sub {
	plan tests => 3;

	my ($logger) = array_logger();
	$logger->debug('first');
	$logger->debug('second');
	my $m = $logger->messages();
	is(scalar(@{$m}), 2, 'two messages recorded');
	is($m->[0]{message}, 'first',  'first message text');
	is($m->[1]{message}, 'second', 'second message text');
};

subtest 'messages() — returns a copy (not the live ref)' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	my $m1 = $logger->messages();
	$logger->debug('after snapshot');
	my $m2 = $logger->messages();
	isnt(scalar(@{$m1}), scalar(@{$m2}), 'snapshot is independent of live store');
};

# ============================================================
# 7. debug() / info() / notice() / trace()
# ============================================================
for my $method (qw(debug info notice trace)) {
	subtest "${method}() — logs message to array" => sub {
		plan tests => 3;

		my ($logger, $log) = array_logger();
		$logger->$method("test $method message");
		is(scalar(@{$log}), 1, "one entry in external array");
		is($log->[0]{level},   $method, "level recorded as '$method'");
		is($log->[0]{message}, "test $method message", 'message text correct');
	};

	subtest "${method}() — respects minimum level filter" => sub {
		plan tests => 1;

		my @log;
		# Set minimum level to 'error' — only error (3) and below should appear
		my $logger = Log::Abstraction->new(array => \@log, level => 'error');
		$logger->$method("should be filtered");
		is(scalar(@log), 0, "$method filtered at level=error");
	};

	subtest "${method}() — arrayref messages flattened" => sub {
		plan tests => 1;

		my ($logger, $log) = array_logger();
		$logger->$method(['part1 ', 'part2']);
		is($log->[0]{message}, 'part1 part2', 'arrayref messages joined');
	};

	subtest "${method}() — trailing newline stripped" => sub {
		plan tests => 1;

		my ($logger, $log) = array_logger();
		$logger->$method("trimmed\n");
		is($log->[0]{message}, 'trimmed', 'trailing newline stripped');
	};

	subtest "${method}() — undefined messages skipped" => sub {
		plan tests => 1;

		my ($logger, $log) = array_logger();
		$logger->$method(undef, 'defined', undef);
		is($log->[0]{message}, 'defined', 'undef entries filtered out');
	};
}

# ============================================================
# 8. warn() via _high_priority
# ============================================================
subtest 'warn() — logs to array' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->warn('a warning');
	is(scalar(@{$log}), 1, 'one entry logged');
	is($log->[0]{level}, 'warn', 'level is warn');
};

subtest 'warn() — hash arg: warning key' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn(warning => 'hash warning');
	is($log->[0]{message}, 'hash warning', 'warning key extracted');
};

subtest 'warn() — warning key with arrayref value' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn(warning => ['part A ', 'part B']);
	is($log->[0]{message}, 'part A part B', 'arrayref warning joined');
};

subtest 'warn() — carp_on_warn fires Carp::carp' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug', carp_on_warn => 1);
	my $carped = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $carped++ };
	$logger->warn('carpable warning');
	is($carped, 1, 'Carp::carp called when carp_on_warn set');
};

subtest 'warn() — no message returns early' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn();
	cmp_ok(scalar(@{$log}), '==', 0, 'no-arg warn does nothing');
};

# ============================================================
# 9. error() via _high_priority
# ============================================================
subtest 'error() — logs to array' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->error('an error'),
	is(scalar(@{$log}), 1, 'one entry logged');
	is($log->[0]{level}, 'error', 'level is error');
};

subtest 'error() — croak_on_error fires Carp::croak' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug', croak_on_error => 1);
	throws_ok(
		sub { $logger->error('fatal-ish') },
		qr/fatal-ish/,
		'Carp::croak thrown when croak_on_error set'
	);
};

subtest 'error() — no croak without croak_on_error' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	lives_ok(sub { $logger->error('gentle error') }, 'no croak without croak_on_error');
	is($log->[0]{message}, 'gentle error', 'message still logged');
};

# ============================================================
# 10. fatal() — synonym for error
# ============================================================
subtest 'fatal() — synonym for error, logs to array' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->fatal('fatal message');
	is(scalar(@{$log}), 1, 'one entry logged');
	is($log->[0]{level}, 'error', 'fatal() maps to error level');
};

subtest 'fatal() — croak_on_error croaks' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug', croak_on_error => 1);
	throws_ok(
		sub { $logger->fatal('kaboom') },
		qr/kaboom/,
		'fatal() croaks when croak_on_error set'
	);
};

# ============================================================
# 11. Logging to a code-ref logger
# ============================================================
subtest 'code-ref logger — called with correct structure' => sub {
	plan tests => 6;

	my %received;
	my $logger = Log::Abstraction->new(
		logger => sub { %received = %{$_[0]} },
		level  => 'debug',
	);
	$logger->debug('coderef test');
	is($received{level},   'debug',        'level passed');
	is($received{message}[0], 'coderef test', 'message passed');
	ok(defined $received{file},  'file passed');
	ok(defined $received{line},  'line passed');
	ok(defined $received{class}, 'class passed');
	ok(!exists $received{ctx},   'no ctx when not set');
};

subtest 'code-ref logger — ctx forwarded when set' => sub {
	plan tests => 1;

	my $got_ctx;
	my $logger = Log::Abstraction->new(
		logger => sub { $got_ctx = $_[0]->{ctx} },
		level  => 'debug',
		ctx    => 'my-context',
	);
	$logger->debug('ctx test');
	is($got_ctx, 'my-context', 'ctx forwarded to code-ref logger');
};

# ============================================================
# 12. Logging to an array-ref logger
# ============================================================
subtest 'array-ref logger — pushes hashref' => sub {
	plan tests => 3;

	my @log;
	my $logger = Log::Abstraction->new(logger => \@log, level => 'debug');
	$logger->info('array ref log');
	is(scalar(@log), 1, 'one entry pushed');
	is($log[0]{level},   'info',          'level correct');
	is($log[0]{message}, 'array ref log', 'message correct');
};

# ============================================================
# 13. Logging to a file-path (string) logger
# ============================================================
subtest 'file-path logger — writes to file' => sub {
	plan tests => 2;

	require File::Temp;
	my $fh   = File::Temp->new(UNLINK => 1, SUFFIX => '.log');
	my $path = $fh->filename();
	close $fh;

	my $logger = Log::Abstraction->new(logger => $path, level => 'debug');
	$logger->info('file path log');

	open(my $in, '<', $path) or die "Cannot read $path: $!";
	my $content = do { local $/; <$in> };
	close $in;

	like($content,  qr/file path log/, 'message written to file');
	like($content,  qr/INFO/i,         'level written to file');
};

# ============================================================
# 14. Logging to a hash-ref logger with file key
# ============================================================
subtest 'hash-ref logger — file key writes to file' => sub {
	plan tests => 2;

	require File::Temp;
	my $fh   = File::Temp->new(UNLINK => 1, SUFFIX => '.log');
	my $path = $fh->filename();
	close $fh;

	my $logger = Log::Abstraction->new(
		logger => { file => $path },
		level  => 'debug',
	);
	$logger->debug('hash logger file');

	open(my $in, '<', $path) or die "Cannot read $path: $!";
	my $content = do { local $/; <$in> };
	close $in;

	like($content, qr/hash logger file/, 'message written via hash-ref file logger');
	like($content, qr/DEBUG/i,            'level written');
};

subtest 'hash-ref logger — array key accumulates' => sub {
	plan tests => 3;

	my @out;
	my $logger = Log::Abstraction->new(
		logger => { array => \@out },
		level  => 'debug',
	);
	$logger->debug('hash array 1');
	$logger->debug('hash array 2');
	is(scalar(@out), 2,            'two entries pushed');
	is($out[0]{message}, 'hash array 1', 'first message');
	is($out[1]{message}, 'hash array 2', 'second message');
};

subtest 'hash-ref logger — invalid filename croaks' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(
		logger => { file => "/tmp/bad\0file" },
		level  => 'debug',
	);
	throws_ok(
		sub { $logger->debug('trigger') },
		qr/Invalid file name/i,
		'null byte in filename causes croak'
	);
};

# ============================================================
# 15. top-level file / fd attributes
# ============================================================
subtest 'top-level file attribute — writes to file' => sub {
	plan tests => 1;

	require File::Temp;
	my $fh   = File::Temp->new(UNLINK => 1, SUFFIX => '.log');
	my $path = $fh->filename();
	close $fh;

	my $logger = Log::Abstraction->new(file => $path, level => 'debug');
	$logger->debug('top-level file test');

	open(my $in, '<', $path) or die $!;
	my $content = do { local $/; <$in> };
	close $in;

	like($content, qr/top-level file test/, 'message written via top-level file attr');
};

subtest 'top-level fd attribute — writes to filehandle' => sub {
	plan tests => 1;

	require File::Temp;
	my $tmp = File::Temp->new(UNLINK => 1, SUFFIX => '.log');

	my $logger = Log::Abstraction->new(fd => $tmp, level => 'debug');
	$logger->debug('fd test');

	seek $tmp, 0, 0;
	my $content = do { local $/; <$tmp> };

	like($content, qr/fd test/, 'message written via top-level fd attr');
};

subtest 'top-level file — tainted filename croaks' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(file => "/bad\0path", level => 'debug');
	throws_ok(
		sub { $logger->debug('tainted') },
		qr/Tainted or unsafe filename/i,
		'tainted top-level file path croaks'
	);
};

# ============================================================
# 16. Object logger delegation
# ============================================================
subtest 'object logger — delegates to method' => sub {
	plan tests => 1;

	my @received;
	my $fake = bless {}, 'FakeLogger';
	{
		no warnings 'once';
		*FakeLogger::debug = sub { push @received, $_[1] };
	}

	my $logger = Log::Abstraction->new(logger => $fake, level => 'debug');
	$logger->debug('delegated');
	is($received[0], 'delegated', 'message delegated to object logger method');
};

subtest 'object logger — notice maps to info when no notice method' => sub {
	plan tests => 1;

	my @received;
	my $fake = bless {}, 'FakeLoggerNoNotice';
	{
		no warnings 'once';
		*FakeLoggerNoNotice::info = sub { push @received, $_[1] };
		# deliberately no notice() method
	}

	my $logger = Log::Abstraction->new(logger => $fake, level => 'debug');
	$logger->notice('notice mapped');
	is($received[0], 'notice mapped', 'notice falls back to info on object logger');
};

subtest 'object logger — unsupported level croaks' => sub {
	plan tests => 1;

	my $fake = bless {}, 'FakeLoggerMinimal';
	{
		no warnings 'once';
		# No methods at all
	}

	my $logger = Log::Abstraction->new(logger => $fake, level => 'debug');
	throws_ok(
		sub { $logger->debug('unsupported') },
		qr/doesn.t know how to deal/i,
		'object logger missing method causes croak'
	);
};

# ============================================================
# 17. Format string expansion
# ============================================================
subtest 'format — %level% %message% %timestamp% expanded' => sub {
	plan tests => 3;

	require File::Temp;
	my $fh   = File::Temp->new(UNLINK => 1, SUFFIX => '.log');
	my $path = $fh->filename();
	close $fh;

	my $logger = Log::Abstraction->new(
		file   => $path,
		level  => 'debug',
		format => '%level%|%message%|%timestamp%',
	);
	$logger->info('fmt test');

	open(my $in, '<', $path) or die $!;
	my $content = do { local $/; <$in> };
	close $in;

	like($content, qr/INFO/,     '%level% expanded');
	like($content, qr/fmt test/, '%message% expanded');
	like($content, qr/\d{4}-\d{2}-\d{2}/, '%timestamp% expanded');
};

subtest 'format — %env_foo% expanded from ENV' => sub {
	plan tests => 1;

	local $ENV{TEST_LOG_VAR} = 'env_value';

	require File::Temp;
	my $fh   = File::Temp->new(UNLINK => 1, SUFFIX => '.log');
	my $path = $fh->filename();
	close $fh;

	my $logger = Log::Abstraction->new(
		file   => $path,
		level  => 'debug',
		format => '%env_TEST_LOG_VAR%',
	);
	$logger->info('env test');

	open(my $in, '<', $path) or die $!;
	my $content = do { local $/; <$in> };
	close $in;

	like($content, qr/env_value/, '%env_foo% expanded from %ENV');
};

# ============================================================
# 18. DESTROY — closelog called when syslog was opened
# ============================================================
subtest 'DESTROY — closelog called when _syslog_opened set' => sub {
	plan tests => 1;

	my $closed = 0;
	my $g = mock_scoped 'Sys::Syslog::closelog' => sub { $closed++ };

	{
		my @log;
		my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
		$logger->{_syslog_opened} = 1;	# Simulate syslog having been opened
	}	# $logger goes out of scope — DESTROY fires

	is($closed, 1, 'closelog called by DESTROY');
};

subtest 'DESTROY — closelog not called when syslog was never opened' => sub {
	plan tests => 1;

	my $closed = 0;
	my $g = mock_scoped 'Sys::Syslog::closelog' => sub { $closed++ };

	{
		my @log;
		my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	}

	is($closed, 0, 'closelog not called when _syslog_opened not set');
};

# ============================================================
# 19. Internal messages store always populated regardless of logger type
# ============================================================
subtest 'internal messages store — populated for code-ref logger' => sub {
	plan tests => 2;

	my $logger = Log::Abstraction->new(logger => sub {}, level => 'debug');
	$logger->debug('internal store test');
	my $m = $logger->messages();
	is(scalar(@{$m}), 1, 'one internal message stored');
	is($m->[0]{message}, 'internal store test', 'message text matches');
};

subtest 'internal messages store — populated for array-ref logger' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(logger => \@log, level => 'debug');
	$logger->info('array store test');
	is(scalar(@{$logger->messages()}), 1, 'internal message stored alongside array-ref logger');
};

# ============================================================
# 20. Edge cases
# ============================================================
subtest 'multiple messages joined correctly' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->debug('hello ', 'world');
	is($log->[0]{message}, 'hello world', 'multiple args joined without separator');
};

subtest 'empty string message stored' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->debug('');
	is($log->[0]{message}, '', 'empty string stored');
};

subtest 'debug filtered when level is info' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'info');
	$logger->debug('should not appear');
	is(scalar(@log), 0, 'debug filtered at info level');
};

subtest 'info passes when level is info' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'info');
	$logger->info('should appear');
	is(scalar(@log), 1, 'info passes at info level');
};

done_testing();
