#!/usr/bin/env perl

# function.t - White-box function tests for Log::Abstraction and its
# Log::Any adapter.  Every public method and every internal helper is
# exercised directly, one module at a time.
#
# Strategy: let all real modules load normally (they are installed).
# Use Test::Mockingbird::mock_scoped to intercept specific outbound calls
# (Carp, Sys::Syslog, Time::HiRes, and helpers in the module itself) only
# where a subtest needs to isolate a function, observe a call, or pin down
# a value such as the clock.  No stub packages needed.
#
# Run with TEST_VERBOSE=1 to see the internal state each subtest inspects.

use strict;
use warnings;

# Sub::Private's runtime check is bypassed under a test harness; set the flag
# so that "perl -Ilib t/function.t" can also call the :Private helpers
BEGIN { $ENV{HARNESS_ACTIVE} //= 1 }

use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util qw(weaken);
use Socket qw(AF_UNIX SOCK_DGRAM sockaddr_un MSG_DONTWAIT);
use Log::Abstraction;
use Test::Most;
use Test::Mockingbird qw(mock_scoped);
use Test::Memory::Cycle;
use Test::Returns;

# Numeric thresholds, as stored in $logger->{level} (syslog numbering)
Readonly::Hash my %LEVEL => (
	emergency => 0,
	alert     => 1,
	critical  => 2,
	error     => 3,
	warning   => 4,
	notice    => 5,
	info      => 6,
	debug     => 7,
);

# Fixed values used across subtests, so expectations aren't magic numbers
Readonly::Hash my %config => (
	epoch          => 86_400,          # 1970-01-02 00:00:00 UTC
	fraction       => 0.125,           # exact in binary, so no rounding noise
	precision      => 3,
	offset_east    => 5 * 3600 + 1800, # +05:30
	offset_west    => -8 * 3600,       # -08:00
	rotate_bytes   => 10,
	rotate_keep    => 2,
	day            => 86_400,
	deep_nesting   => 600,             # beyond JSON::PP's default max_depth
	marker         => 'function-test-marker',
);

# Print internal state only when asked, so normal runs stay quiet
sub vdiag {
	diag(@_) if($ENV{TEST_VERBOSE});
	return;
}

my $TMPDIR = tempdir(CLEANUP => 1);

# ---------------------------------------------------------------------------
# Helper: build a logger that writes to an in-memory array ref
# ---------------------------------------------------------------------------
sub array_logger {
	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	return ($logger, \@log);
}

# ============================================================
# 1. new() - basic construction
# ============================================================
subtest 'new() - scalar logger arg' => sub {
	plan tests => 3;

	my $logger = Log::Abstraction->new('somefile.log');
	ok(defined $logger, 'object created');
	isa_ok($logger, 'Log::Abstraction');
	is($logger->{logger}, 'somefile.log', 'logger attribute stored');
};

subtest 'new() - hash args' => sub {
	plan tests => 3;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	ok(defined $logger, 'object created');
	isa_ok($logger, 'Log::Abstraction');
	is(ref($logger->{array}), 'ARRAY', 'array attribute is ARRAY ref');
};

subtest 'new() - hashref arg' => sub {
	plan tests => 2;

	my @log;
	my $logger = Log::Abstraction->new({ array => \@log, level => 'info' });
	ok(defined $logger, 'object created from hashref');
	isa_ok($logger, 'Log::Abstraction');
};

subtest 'new() - default level is warning' => sub {
	plan tests => 1;

	# Default level stored as integer 4 (warning)
	my $logger = Log::Abstraction->new('somefile.log');
	is($logger->{level}, $LEVEL{warning}, 'default level is warning');
};

subtest 'new() - explicit level stored as integer' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	is($logger->{level}, $LEVEL{debug}, 'debug level stored as its number');
};

subtest 'new() - invalid level croaks' => sub {
	plan tests => 1;

	throws_ok(
		sub { Log::Abstraction->new(array => [], level => 'bogus') },
		qr/invalid syslog level/i,
		'invalid level causes croak'
	);
};

subtest 'new() - croaks when encapsulating self' => sub {
	plan tests => 1;

	my @log;
	my $inner = Log::Abstraction->new(array => \@log, level => 'debug');
	throws_ok(
		sub { Log::Abstraction->new(logger => $inner) },
		qr/needless indirection/i,
		'encapsulating Log::Abstraction croaks'
	);
};

subtest 'new() - clone with no args' => sub {
	plan tests => 4;

	my @log;
	my $orig  = Log::Abstraction->new(array => \@log, level => 'debug');
	my $clone = $orig->new();
	isa_ok($clone, 'Log::Abstraction');
	isnt($clone, $orig, 'clone is a different object');
	is($clone->{level}, $orig->{level}, 'clone inherits level');
	isnt($clone->{messages}, $orig->{messages}, 'messages array is a deep copy');
};

subtest 'new() - clone with overrides' => sub {
	plan tests => 2;

	my @log;
	my $orig  = Log::Abstraction->new(array => \@log, level => 'debug');
	my $clone = $orig->new(level => 'info');
	is($clone->{level}, $LEVEL{info}, 'clone overrides level to info');
	is($orig->{level}, $LEVEL{debug}, 'original level unchanged');
};

subtest 'new() - messages initialised as empty arrayref' => sub {
	plan tests => 2;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	is(ref($logger->{messages}), 'ARRAY', 'messages is ARRAY ref');
	is(scalar(@{$logger->{messages}}), 0, 'messages starts empty');
};

# ============================================================
# 2. _sanitize_email_header()  (internal - call via full name)
# ============================================================
subtest '_sanitize_email_header() - undef input returns undef' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header(undef);
	ok(!defined($result), 'undef input returns undef');
};

subtest '_sanitize_email_header() - strips LF' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header("foo\nbar");
	is($result, 'foobar', 'LF stripped');
};

subtest '_sanitize_email_header() - strips CR' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header("foo\rbar");
	is($result, 'foobar', 'CR stripped');
};

subtest '_sanitize_email_header() - strips CRLF' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header("foo\r\nbar");
	is($result, 'foobar', 'CRLF stripped');
};

subtest '_sanitize_email_header() - clean string unchanged' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header('user@example.com');
	is($result, 'user@example.com', 'clean value returned unchanged');
};

subtest '_sanitize_email_header() - multiple injections all stripped' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header("a\r\nb\nc\rd");
	is($result, 'abcd', 'all CR/LF characters stripped');
};

# ============================================================
# 3. _log() - private method enforcement
# ============================================================
subtest '_log() - croaks when called from outside the package' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	throws_ok(
		sub { $logger->_log('debug', 'msg') },
		qr/Illegal Operation.*private/i,
		'_log croaks when called from outside Log::Abstraction'
	);
};

# ============================================================
# 4. level() - getter / setter
# ============================================================
subtest 'level() - getter returns integer' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	my $l = $logger->level();
	ok(defined($l) && $l =~ /^\d+$/, 'level() returns an integer');
};

subtest 'level() - setter updates value' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->level('info');
	is($logger->{level}, $LEVEL{info}, 'level updated to info');
};

subtest 'level() - setter with invalid value warns and returns undef' => sub {
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
subtest 'is_debug() - true when level is debug' => sub {
	plan tests => 1;

	my ($logger) = array_logger();	# constructed with level => 'debug'
	is($logger->is_debug(), 1, 'is_debug true at debug level');
};

subtest 'is_debug() - false when level is warning' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'warning');
	is($logger->is_debug(), 0, 'is_debug false at warning level');
};

subtest 'is_debug() - false when level is error' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'error');
	is($logger->is_debug(), 0, 'is_debug false at error level');
};

# ============================================================
# 6. messages()
# ============================================================
subtest 'messages() - returns empty arrayref initially' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	my $m = $logger->messages();
	is(ref($m), 'ARRAY', 'messages() returns ARRAY ref');
	is(scalar(@{$m}), 0, 'messages() is empty initially');
};

subtest 'messages() - accumulates logged messages' => sub {
	plan tests => 3;

	my ($logger) = array_logger();
	$logger->debug('first');
	$logger->debug('second');
	my $m = $logger->messages();
	is(scalar(@{$m}), 2, 'two messages recorded');
	is($m->[0]{message}, 'first',  'first message text');
	is($m->[1]{message}, 'second', 'second message text');
};

subtest 'messages() - returns a copy (not the live ref)' => sub {
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
	subtest "${method}() - logs message to array" => sub {
		plan tests => 3;

		my ($logger, $log) = array_logger();
		$logger->$method("test $method message");
		is(scalar(@{$log}), 1, "one entry in external array");
		is($log->[0]{level},   $method, "level recorded as '$method'");
		is($log->[0]{message}, "test $method message", 'message text correct');
	};

	subtest "${method}() - respects minimum level filter" => sub {
		plan tests => 1;

		my @log;
		# Set minimum level to 'error' - only error (3) and below should appear
		my $logger = Log::Abstraction->new(array => \@log, level => 'error');
		$logger->$method("should be filtered");
		is(scalar(@log), 0, "$method filtered at level=error");
	};

	subtest "${method}() - arrayref messages flattened" => sub {
		plan tests => 1;

		my ($logger, $log) = array_logger();
		$logger->$method(['part1 ', 'part2']);
		is($log->[0]{message}, 'part1 part2', 'arrayref messages joined');
	};

	subtest "${method}() - trailing newline stripped" => sub {
		plan tests => 1;

		my ($logger, $log) = array_logger();
		$logger->$method("trimmed\n");
		is($log->[0]{message}, 'trimmed', 'trailing newline stripped');
	};

	subtest "${method}() - undefined messages skipped" => sub {
		plan tests => 1;

		my ($logger, $log) = array_logger();
		$logger->$method(undef, 'defined', undef);
		is($log->[0]{message}, 'defined', 'undef entries filtered out');
	};
}

# ============================================================
# 8. warn() via _high_priority
# ============================================================
subtest 'warn() - logs to array' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->warn('a warning');
	is(scalar(@{$log}), 1, 'one entry logged');
	is($log->[0]{level}, 'warn', 'level is warn');
};

subtest 'warn() - hash arg: warning key' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn(warning => 'hash warning');
	is($log->[0]{message}, 'hash warning', 'warning key extracted');
};

subtest 'warn() - warning key with arrayref value' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn(warning => ['part A ', 'part B']);
	is($log->[0]{message}, 'part A part B', 'arrayref warning joined');
};

subtest 'warn() - carp_on_warn fires Carp::carp' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug', carp_on_warn => 1);
	my $carped = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $carped++ };
	$logger->warn('carpable warning');
	is($carped, 1, 'Carp::carp called when carp_on_warn set');
};

subtest 'warn() - no message returns early' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn();
	cmp_ok(scalar(@{$log}), '==', 0, 'no-arg warn does nothing');
};

# ============================================================
# 9. error() via _high_priority
# ============================================================
subtest 'error() - logs to array' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->error('an error'),
	is(scalar(@{$log}), 1, 'one entry logged');
	is($log->[0]{level}, 'error', 'level is error');
};

subtest 'error() - croak_on_error fires Carp::croak' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug', croak_on_error => 1);
	throws_ok(
		sub { $logger->error('fatal-ish') },
		qr/fatal-ish/,
		'Carp::croak thrown when croak_on_error set'
	);
};

subtest 'error() - no croak without croak_on_error' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	lives_ok(sub { $logger->error('gentle error') }, 'no croak without croak_on_error');
	is($log->[0]{message}, 'gentle error', 'message still logged');
};

# ============================================================
# 10. fatal() - synonym for error
# ============================================================
subtest 'fatal() - synonym for error, logs to array' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->fatal('fatal message');
	is(scalar(@{$log}), 1, 'one entry logged');
	is($log->[0]{level}, 'error', 'fatal() maps to error level');
};

subtest 'fatal() - croak_on_error croaks' => sub {
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
subtest 'code-ref logger - called with correct structure' => sub {
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

subtest 'code-ref logger - ctx forwarded when set' => sub {
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
subtest 'array-ref logger - pushes hashref' => sub {
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
subtest 'file-path logger - writes to file' => sub {
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
subtest 'hash-ref logger - file key writes to file' => sub {
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

subtest 'hash-ref logger - array key accumulates' => sub {
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

subtest 'hash-ref logger - invalid filename croaks' => sub {
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
subtest 'top-level file attribute - writes to file' => sub {
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

subtest 'top-level fd attribute - writes to filehandle' => sub {
	plan tests => 1;

	require File::Temp;
	my $tmp = File::Temp->new(UNLINK => 1, SUFFIX => '.log');

	my $logger = Log::Abstraction->new(fd => $tmp, level => 'debug');
	$logger->debug('fd test');

	seek $tmp, 0, 0;
	my $content = do { local $/; <$tmp> };

	like($content, qr/fd test/, 'message written via top-level fd attr');
};

subtest 'top-level file - tainted filename croaks' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(file => "/bad\0path", level => 'debug');
	throws_ok(
		sub { $logger->debug('tainted') },
		qr/Invalid file name/i,
		'tainted top-level file path croaks'
	);
};

# ============================================================
# 16. Object logger delegation
# ============================================================
subtest 'object logger - delegates to method' => sub {
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

subtest 'object logger - notice maps to info when no notice method' => sub {
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

subtest 'object logger - unsupported level croaks' => sub {
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
subtest 'format - %level% %message% %timestamp% expanded' => sub {
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

subtest 'format - %env_foo% expanded from ENV' => sub {
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
# 18. DESTROY - closelog called when syslog was opened
# ============================================================
subtest 'DESTROY - closelog called when _syslog_opened set' => sub {
	plan tests => 1;

	my $closed = 0;
	my $g = mock_scoped 'Sys::Syslog::closelog' => sub { $closed++ };

	{
		my @log;
		my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
		$logger->{_syslog_opened} = 1;	# Simulate syslog having been opened
	}	# $logger goes out of scope - DESTROY fires

	is($closed, 1, 'closelog called by DESTROY');
};

subtest 'DESTROY - closelog not called when syslog was never opened' => sub {
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
subtest 'internal messages store - populated for code-ref logger' => sub {
	plan tests => 2;

	my $logger = Log::Abstraction->new(logger => sub {}, level => 'debug');
	$logger->debug('internal store test');
	my $m = $logger->messages();
	is(scalar(@{$m}), 1, 'one internal message stored');
	is($m->[0]{message}, 'internal store test', 'message text matches');
};

subtest 'internal messages store - populated for array-ref logger' => sub {
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

# ============================================================
# 20. _level_number() - names and numbers to thresholds
# ============================================================
# Backend 'level' keys accept a name in any case or a syslog number 0-7;
# anything else must be undef so that new() can reject it.
subtest '_level_number() - names, numbers and junk' => sub {
	for my $name (sort keys %LEVEL) {
		is(Log::Abstraction::_level_number(uc($name)), $LEVEL{$name}, "name '\U$name\E' is case-insensitive");
	}
	is(Log::Abstraction::_level_number('warn'), $LEVEL{warning}, "'warn' is a synonym of warning");
	for my $n (0 .. $LEVEL{debug}) {
		is(Log::Abstraction::_level_number($n), $n, "number $n passes through");
	}
	returns_ok(Log::Abstraction::_level_number('3'), { type => 'integer' }, 'a number comes back as an integer');
	for my $bad ($LEVEL{debug} + 1, -1, '', 'bogus', '1.5', undef) {
		ok(!defined(Log::Abstraction::_level_number($bad)), 'rejects ' . ($bad // 'undef'));
	}
};

# ============================================================
# 21. _wants() - the per-backend level gate
# ============================================================
# A backend level only narrows what the logger already lets through: no level
# means everything, otherwise the message must be at least as severe.
subtest '_wants() - per-backend level gate' => sub {
	ok(Log::Abstraction::_wants('debug', undef), 'no backend level lets everything through');
	ok(Log::Abstraction::_wants('error', 'warning'), 'more severe than the backend level passes');
	ok(Log::Abstraction::_wants('warn', 'warning'), 'equal to the backend level passes');
	ok(!Log::Abstraction::_wants('info', 'warning'), 'less severe than the backend level is dropped');
	ok(Log::Abstraction::_wants('error', $LEVEL{error}), 'a numeric backend level works');
	ok(!Log::Abstraction::_wants('emergency', 'bogus'), 'an unknown backend level lets nothing through');

	# _wants must use _level_number rather than its own parsing
	my @seen;
	my $g = mock_scoped 'Log::Abstraction::_level_number' => sub { push @seen, $_[0]; return $LEVEL{error} };
	ok(Log::Abstraction::_wants('critical', 'anything'), 'delegates to _level_number');
	is_deeply(\@seen, ['anything'], '_level_number got the backend level');
};

# ============================================================
# 22. _backend() - plain and hash forms
# ============================================================
subtest '_backend() - plain value, hash form, handle object' => sub {
	is_deeply([ Log::Abstraction::_backend('file', '/x.log') ], [ '/x.log', undef, undef ], 'plain value is the destination');
	is_deeply(
		[ Log::Abstraction::_backend('fd', { fd => \*STDERR, level => 'error', format => '%message%' }) ],
		[ \*STDERR, 'error', '%message%' ],
		'hash form splits destination, level and format'
	);
	my $array = [];
	is_deeply([ Log::Abstraction::_backend('array', $array) ], [ $array, undef, undef ], 'an array ref is a destination');

	# A blessed hash (e.g. an IO::Handle subclass) is a handle, not the hash form
	my $object = bless({ fd => 'not me' }, 'Some::Handle');
	is((Log::Abstraction::_backend('fd', $object))[0], $object, 'a blessed hash is a destination');
};

# ============================================================
# 23. _to_json() - cached canonical encoder that never dies
# ============================================================
subtest '_to_json() - canonical, safe with objects, never dies' => sub {
	my $json = Log::Abstraction::_to_json({ b => 2, a => 1, c => [ 1, 'x' ] });
	is($json, '{"a":1,"b":2,"c":[1,"x"]}', 'compact with sorted keys');
	returns_ok($json, { type => 'string' }, 'returns a string');

	is(Log::Abstraction::_to_json({ o => bless({}, 'Obj') }), '{"o":null}', 'a blessed object becomes null instead of dying');

	# Characters, not UTF-8 bytes: _write_line does the encoding once
	my $wide = Log::Abstraction::_to_json([ "caf\x{e9} \x{263A}" ]);
	like($wide, qr/\x{263A}/, 'wide characters are left as characters');

	# Deeper than JSON::PP allows: logging must fall back, not die
	my $deep = [];
	my $p = $deep;
	$p = $p->[0] = [] for(1 .. $config{deep_nesting});
	my $fallback;
	lives_ok(sub { $fallback = Log::Abstraction::_to_json($deep) }, 'over-deep data does not die');
	like($fallback, qr/^ARRAY\(0x[0-9a-f]+\)$/, 'falls back to Perl stringification');
};

# ============================================================
# 24. _field_string() - one field value as text
# ============================================================
{
	package Function::Test::Stringy;
	use overload '""' => sub { 'stringy!' }, fallback => 1;
}

subtest '_field_string() - undef, scalars, objects and references' => sub {
	is(Log::Abstraction::_field_string(undef), '', 'undef is the empty string');
	is(Log::Abstraction::_field_string(42), '42', 'a number is itself');
	is(Log::Abstraction::_field_string(bless({}, 'Function::Test::Stringy')), 'stringy!', 'overloaded stringification is honoured');

	# Unblessed references go through _to_json and nothing else
	my @seen;
	my $g = mock_scoped 'Log::Abstraction::_to_json' => sub { push @seen, $_[0]; return 'JSON' };
	my $ref = { k => 'v' };
	is(Log::Abstraction::_field_string($ref), 'JSON', 'a reference is JSON-encoded');
	is(scalar(@seen), 1, '_to_json called once');
	is($seen[0], $ref, '... with the reference itself');
	is(Log::Abstraction::_field_string('plain'), 'plain', 'a scalar does not reach _to_json');
	is(scalar(@seen), 1, '_to_json not called for a scalar');
};

# ============================================================
# 25. _fields_text() - logfmt rendering
# ============================================================
# The point of the quoting rules is that a field value can never break the
# line, so a field can't forge a separate log entry.
subtest '_fields_text() - quoting, escaping and key sanitising' => sub {
	my $text = Log::Abstraction::_fields_text({
		'a b' => 'x y',
		e     => '',
		n     => "l\nm\x01",
		r     => [1],
		o     => undef,
		q     => q{"\\},
		z     => 'plain',
	});
	vdiag("fields text: $text");
	is($text, q{a_b="x y" e="" n="l\nm\x01" o="" q="\"\\\\" r=[1] z=plain}, 'rendered as expected');
	unlike($text, qr/[\x00-\x1F]/, 'no raw control characters survive');
	is(Log::Abstraction::_fields_text({}), '', 'no fields is the empty string');
	is(Log::Abstraction::_fields_text({ "k\n=x" => 1 }), 'k__x=1', 'unsafe key characters become underscores');
};

# ============================================================
# 26. _check_timestamp_args() - constructor validation
# ============================================================
subtest '_check_timestamp_args() - exact errors' => sub {
	my $class = 'Log::Abstraction';
	for my $bad (undef, '', []) {
		throws_ok(
			sub { Log::Abstraction::_check_timestamp_args($class, { timestamp_format => $bad }) },
			qr/^\Q$class: timestamp_format must be a non-empty string\E at /,
			'timestamp_format ' . (defined($bad) ? "'$bad'" : 'undef') . ' rejected'
		);
	}
	for my $bad ('x', -1, 10, '1.5') {
		throws_ok(
			sub { Log::Abstraction::_check_timestamp_args($class, { timestamp_precision => $bad }) },
			qr/^\Q$class: timestamp_precision must be an integer from 0 to 9, not '$bad'\E at /,
			"timestamp_precision '$bad' rejected"
		);
	}
	lives_ok(sub { Log::Abstraction::_check_timestamp_args($class, { timestamp_format => '%s', timestamp_precision => 9 }) }, 'valid values pass');
	lives_ok(sub { Log::Abstraction::_check_timestamp_args($class, {}) }, 'no options pass');

	# Also applied when cloning, so a clone can't smuggle in a bad value
	my ($logger) = array_logger();
	throws_ok(sub { $logger->new(timestamp_precision => 'x') }, qr/timestamp_precision must be/, 'clone path validates too');
};

# ============================================================
# 27. _utc_offset()
# ============================================================
subtest '_utc_offset() - UTC and local offsets' => sub {
	is(Log::Abstraction::_utc_offset($config{epoch}, 1), 0, 'UTC is always offset 0');

	# Whatever the local zone, the offset is whole quarter-hours within +-14h
	my $offset = Log::Abstraction::_utc_offset($config{epoch}, 0);
	vdiag("local UTC offset: $offset");
	returns_ok($offset, { type => 'integer' }, 'returns an integer');
	is($offset % 900, 0, 'a whole number of quarter-hours');
	cmp_ok(abs($offset), '<=', 14 * 3600, 'within 14 hours');
};

# ============================================================
# 28. _check_rotate_args() - validation and normalisation
# ============================================================
subtest '_check_rotate_args() - sizes, intervals, keep' => sub {
	my $class = 'Log::Abstraction';
	my %sizes = ('100' => 100, '2k' => 2048, '3 MB' => 3 * 1024 ** 2, '1G' => 1024 ** 3, ' 5kb ' => 5 * 1024);
	for my $in (sort keys %sizes) {
		my %args = (rotate_size => $in);
		Log::Abstraction::_check_rotate_args($class, \%args);
		is($args{rotate_size}, $sizes{$in}, "rotate_size '$in' is $sizes{$in} bytes");
	}
	for my $bad ('0', '0k', 'big', '1.5M', '-1', '') {
		throws_ok(
			sub { Log::Abstraction::_check_rotate_args($class, { rotate_size => $bad }) },
			qr/^\Q$class: rotate_size must be a positive number of bytes, optionally with K, M or G, not '$bad'\E at /,
			"rotate_size '$bad' rejected"
		);
	}

	my %args = (rotate_interval => 'DAILY');
	Log::Abstraction::_check_rotate_args($class, \%args);
	is($args{rotate_interval}, 'daily', 'rotate_interval is lower-cased');
	throws_ok(
		sub { Log::Abstraction::_check_rotate_args($class, { rotate_interval => 'fortnightly' }) },
		qr/^\Q$class: rotate_interval must be hourly, daily, weekly or monthly, not 'fortnightly'\E at /,
		'unknown interval rejected'
	);

	lives_ok(sub { Log::Abstraction::_check_rotate_args($class, { rotate_keep => 0 }) }, 'rotate_keep 0 is allowed');
	throws_ok(
		sub { Log::Abstraction::_check_rotate_args($class, { rotate_keep => -1 }) },
		qr/^\Q$class: rotate_keep must be a non-negative integer, not '-1'\E at /,
		'negative keep rejected'
	);
};

# ============================================================
# 29. _rotate() - shifting files on size and on period change
# ============================================================
# Fixtures are written :raw so byte counts don't change with CRLF platforms.
sub write_raw {
	my ($path, $content) = @_;
	open(my $fh, '>:raw', $path) or die "$path: $!";
	print $fh $content;
	close $fh;
	return;
}

sub read_raw {
	my $path = shift;
	open(my $fh, '<:raw', $path) or return;
	local $/;
	return scalar(<$fh>);
}

subtest '_rotate() - size-based shift and keep limit' => sub {
	my $path = File::Spec->catfile($TMPDIR, 'rotate-size.log');
	my $logger = Log::Abstraction->new(array => [], rotate_size => $config{rotate_bytes}, rotate_keep => $config{rotate_keep});

	Log::Abstraction::_rotate($logger, $path);
	ok(!-e "$path.1", 'no file yet: nothing to rotate');

	write_raw($path, 'short');
	Log::Abstraction::_rotate($logger, $path);
	ok(-e $path && !-e "$path.1", 'under the size: not rotated');

	# Three rotations with keep=2: the oldest generation must be dropped
	for my $gen (qw(first second third)) {
		write_raw($path, $gen x $config{rotate_bytes});
		Log::Abstraction::_rotate($logger, $path);
	}
	ok(!-e $path, 'the live file was moved away');
	like(read_raw("$path.1"), qr/^third/, '.1 is the newest');
	like(read_raw("$path.2"), qr/^second/, '.2 is the one before');
	ok(!-e "$path.3", 'nothing beyond rotate_keep');
};

subtest '_rotate() - rotate_keep 0 deletes' => sub {
	my $path = File::Spec->catfile($TMPDIR, 'rotate-zero.log');
	my $logger = Log::Abstraction->new(array => [], rotate_size => $config{rotate_bytes}, rotate_keep => 0);
	write_raw($path, 'x' x $config{rotate_bytes});
	Log::Abstraction::_rotate($logger, $path);
	ok(!-e $path, 'file deleted');
	ok(!-e "$path.1", 'no copy kept');
};

subtest '_rotate() - time-based uses the file mtime' => sub {
	my $path = File::Spec->catfile($TMPDIR, 'rotate-daily.log');
	my $logger = Log::Abstraction->new(array => [], rotate_interval => 'daily', utc => 1);

	write_raw($path, 'today');
	Log::Abstraction::_rotate($logger, $path);
	ok(-e $path && !-e "$path.1", 'written today: not rotated');

	my $old = time() - 2 * $config{day};
	utime($old, $old, $path) or die "utime: $!";
	Log::Abstraction::_rotate($logger, $path);
	ok(!-e $path, 'last written two days ago: rotated');
	is(read_raw("$path.1"), 'today', 'content moved to .1');
};

# ============================================================
# 30. _timestamp() - formatting, precision, offsets
# ============================================================
# A bare blessed hash stands in for a logger: _timestamp only reads options.
sub ts_logger {
	return bless({ utc => 1, @_ }, 'Log::Abstraction');
}

subtest '_timestamp() - formats with a fixed clock' => sub {
	my $now = $config{epoch} + $config{fraction};

	is(Log::Abstraction::_timestamp(ts_logger(), $now), '1970-01-02 00:00:00', 'default format');
	is(
		Log::Abstraction::_timestamp(ts_logger(timestamp_precision => $config{precision}), $now),
		'1970-01-02 00:00:00.125', 'precision appends truncated fractional seconds'
	);
	is(Log::Abstraction::_timestamp(ts_logger(timestamp_format => 'ISO8601'), $now), '1970-01-02T00:00:00Z', 'iso8601 in UTC ends with Z');
	is(Log::Abstraction::_timestamp(ts_logger(timestamp_format => 'rfc3339'), $now), '1970-01-02T00:00:00Z', 'rfc3339 is the same');
	is(Log::Abstraction::_timestamp(ts_logger(timestamp_format => '%N|%3N|%1N'), $now), '125000000|125|1', '%N widths truncate');
	is(Log::Abstraction::_timestamp(ts_logger(timestamp_format => '%%N %%z %Z'), $now), '%N %z UTC', "'%%' keeps the token literal; %Z is UTC");
	is(
		Log::Abstraction::_timestamp(ts_logger(timestamp_format => '%%S', timestamp_precision => $config{precision}), $now),
		'%S', 'precision does not touch an escaped %%S'
	);
	returns_ok(Log::Abstraction::_timestamp(ts_logger(), $now), { type => 'string' }, 'returns a string');
};

subtest '_timestamp() - offsets come from _utc_offset' => sub {
	# Mock the helper so the expected text doesn't depend on the local zone
	for my $case ([ $config{offset_east}, '+0530 +05:30' ], [ $config{offset_west}, '-0800 -08:00' ]) {
		my ($offset, $want) = @{$case};
		my $g = mock_scoped 'Log::Abstraction::_utc_offset' => sub { $offset };
		is(Log::Abstraction::_timestamp(ts_logger(utc => 0, timestamp_format => '%z %:z'), $config{epoch}), $want, "offset $offset");
	}
};

subtest '_timestamp() - reads Time::HiRes::time when no time is given' => sub {
	my $g = mock_scoped 'Time::HiRes::time' => sub { $config{epoch} + $config{fraction} };
	is(Log::Abstraction::_timestamp(ts_logger(timestamp_format => '%H:%M:%S.%3N')), '00:00:00.125', 'uses the mocked clock');
};

# ============================================================
# 31. _validate_file_path()
# ============================================================
subtest '_validate_file_path() - accepts safe paths, rejects the rest' => sub {
	my ($logger) = array_logger();
	my $good = File::Spec->catfile($TMPDIR, 'ok-name_1.log');
	is(Log::Abstraction::_validate_file_path($logger, $good), $good, 'a safe path is returned unchanged');

	for my $bad ('a<b', 'a>b', 'a|b', 'a*b', 'a?b', 'a;b', 'a!b', 'a`b', 'a$b', 'a"b', "a\0b", "a\tb", '../etc/passwd', 'x/../y', "a.log\n") {
		(my $shown = $bad) =~ s/([\x00-\x1F])/sprintf('\\x%02x', ord($1))/ge;
		throws_ok(
			sub { Log::Abstraction::_validate_file_path($logger, $bad) },
			qr/^\QLog::Abstraction: Invalid file name: $bad\E at /,
			"rejects '$shown'"
		);
	}
};

# ============================================================
# 32. _write_line() - paths, handles, encoding, rotation hook
# ============================================================
subtest '_write_line() - file path appends and calls _rotate only if configured' => sub {
	my $path = File::Spec->catfile($TMPDIR, 'write-line.log');
	my @rotated;
	my $g = mock_scoped 'Log::Abstraction::_rotate' => sub { push @rotated, $_[1] };

	# A character string (utf8 flag on) is encoded; byte strings pass as-is
	my $chars = "caf\x{e9}";
	utf8::upgrade($chars);
	my ($plain) = array_logger();
	Log::Abstraction::_write_line($plain, $path, 'one');
	Log::Abstraction::_write_line($plain, $path, $chars);
	is(scalar(@rotated), 0, 'no rotation options: _rotate not called');
	(my $content = read_raw($path)) =~ s/\r\n/\n/g;
	is($content, "one\ncaf\xc3\xa9\n", 'lines appended, characters written as UTF-8');

	my $rotating = Log::Abstraction->new(array => [], rotate_size => '1k');
	Log::Abstraction::_write_line($rotating, $path, 'two');
	is_deeply(\@rotated, [$path], '_rotate called with the path');
};

subtest '_write_line() - a failing rotation still writes the line' => sub {
	my $path = File::Spec->catfile($TMPDIR, 'write-after-failed-rotate.log');
	my $g = mock_scoped 'Log::Abstraction::_rotate' => sub { die "rename failed\n" };
	my $logger = Log::Abstraction->new(array => [], rotate_size => '1k');
	lives_ok(sub { Log::Abstraction::_write_line($logger, $path, 'kept') }, 'does not die');
	like(read_raw($path), qr/^kept\r?\n\z/, 'line written');
};

subtest '_write_line() - handles: encoding layers respected, I/O errors silent' => sub {
	my ($logger) = array_logger();

	my $raw = '';
	open(my $rfh, '>', \$raw) or die $!;
	Log::Abstraction::_write_line($logger, $rfh, "\x{263A}");
	close $rfh;
	is($raw, "\xe2\x98\xba\n", 'a raw handle gets UTF-8 bytes');

	my $layered = '';
	open(my $lfh, '>:encoding(UTF-8)', \$layered) or die $!;
	Log::Abstraction::_write_line($logger, $lfh, "\x{263A}");
	close $lfh;
	is($layered, "\xe2\x98\xba\n", 'an :encoding handle is not double-encoded');

	my $missing = File::Spec->catfile($TMPDIR, 'no-such-dir', 'x.log');
	lives_ok(sub { Log::Abstraction::_write_line($logger, $missing, 'lost') }, 'an unopenable path does not die');
};

# ============================================================
# 33. _journald_send() - native protocol framing
# ============================================================
subtest '_journald_send() - text and binary framing' => sub {
	my $ok = eval { socket(my $probe, AF_UNIX, SOCK_DGRAM, 0) or die "$!\n"; close $probe; 1 };
	plan skip_all => 'Unix domain sockets not available' unless($ok);

	my $sockpath = File::Spec->catfile($TMPDIR, 'journal.socket');
	socket(my $recv, AF_UNIX, SOCK_DGRAM, 0) or die "socket: $!";
	bind($recv, sockaddr_un($sockpath)) or die "bind: $!";

	my $chars = "caf\x{e9}";
	utf8::upgrade($chars);
	my ($logger) = array_logger();
	Log::Abstraction::_journald_send($logger, $sockpath, MESSAGE => "two\nlines", PRIORITY => $LEVEL{info}, NAME => $chars);

	my $data = '';
	recv($recv, $data, 65536, MSG_DONTWAIT);
	close $recv;
	vdiag('journald datagram: ' . join(' ', map { sprintf('%02x', ord) } split(//, $data)));

	my $value = "two\nlines";
	my $want = "MESSAGE\n" . pack('VV', length($value), 0) . "$value\n"
		. "NAME=caf\xc3\xa9\n"
		. "PRIORITY=$LEVEL{info}\n";
	is($data, $want, 'sorted fields; newline value binary-framed; characters UTF-8 encoded');

	throws_ok(
		sub { Log::Abstraction::_journald_send($logger, File::Spec->catfile($TMPDIR, 'nobody.socket'), MESSAGE => 'x') },
		qr/^Can't send to \Q$TMPDIR\E/,
		'a missing socket croaks (the caller turns this into one carp)'
	);
};

# ============================================================
# 34. _format_message() - token expansion
# ============================================================
{
	package Function::Test::Subclass;
	our @ISA = ('Log::Abstraction');
}

subtest '_format_message() - tokens, class suppression, injection safety' => sub {
	my ($base) = array_logger();
	my $fmt = '%level%|%class%|%callstack%|%message%|%timestamp%';
	my @where = ('prog.pl', 12);

	is(
		Log::Abstraction::_format_message($base, 'warn', 'hi', 1, @where, undef, 'TS', $fmt),
		'WARN||prog.pl 12|hi|TS',
		'tokens expanded; base class shows no %class%'
	);

	my $sub = Function::Test::Subclass->new(array => []);
	is(
		Log::Abstraction::_format_message($sub, 'info', 'hi', 1, @where, undef, 'TS', '%class%'),
		'Function::Test::Subclass', 'a subclass is named'
	);

	local $ENV{FUNCTION_TEST_SECRET} = $config{marker};
	is(Log::Abstraction::_format_message($base, 'info', 'x', 1, @where, undef, 'TS', '%env_FUNCTION_TEST_SECRET%'), $config{marker}, '%env_*% expanded from the format');
	is(Log::Abstraction::_format_message($base, 'info', '%env_FUNCTION_TEST_SECRET%', 1, @where, undef, 'TS', '%message%'), '%env_FUNCTION_TEST_SECRET%', 'but never from the message');
	is(Log::Abstraction::_format_message($base, 'info', 'x', 1, @where, undef, 'TS', '[%env_FUNCTION_TEST_UNSET_ZZZ%]'), '[]', 'an unset variable is empty');

	is(Log::Abstraction::_format_message($base, 'info', "a\r\nb\nc", 1, @where, undef, 'TS', '%message%'), "a\n\tb\n\tc", 'continuation lines indented so they cannot forge entries');
	is(Log::Abstraction::_format_message($base, 'info', 'm', 1, @where, { k => 'v' }, 'TS', '%message%'), 'm k=v', 'fields appended as logfmt');

	# The logger's own format is used when none is passed, the default when '' is
	my $own = Log::Abstraction->new(array => [], format => '<%message%>');
	is(Log::Abstraction::_format_message($own, 'info', 'm', 1, @where, undef, 'TS'), '<m>', "undef format means the logger's");
	is(Log::Abstraction::_format_message($base, 'info', 'm', 0, @where, undef, 'TS', ''), 'INFO> [TS] prog.pl 12 m', "'' falls back to the default");
};

subtest '_format_message() - JSON lines' => sub {
	my $sub = Function::Test::Subclass->new(array => []);
	my $json = Log::Abstraction::_format_message($sub, 'error', 'boom', 1, 'p.pl', '7', { obj => bless({}, 'Function::Test::Stringy') }, 'TS', 'json');
	is(
		$json,
		'{"class":"Function::Test::Subclass","fields":{"obj":"stringy!"},"file":"p.pl","level":"error","line":7,"message":"boom","timestamp":"TS"}',
		'class for a subclass, objects stringified, line numeric'
	);

	# The timestamp is computed only when the caller didn't pass one
	my $g = mock_scoped 'Log::Abstraction::_timestamp' => sub { 'MOCKED' };
	my ($base) = array_logger();
	like(Log::Abstraction::_format_message($base, 'info', 'm', 1, 'p', 1, undef, undef, 'json'), qr/"timestamp":"MOCKED"/, 'undef timestamp asks _timestamp');
	unlike(Log::Abstraction::_format_message($base, 'info', 'm', 1, 'p', 1, undef, undef, 'json'), qr/"class"/, 'no class key for the base class');
};

# ============================================================
# 35. _log() - dispatch to each backend
# ============================================================
subtest '_log() - CODE backend gets the caller location and copied fields' => sub {
	my @calls;
	my $logger = Log::Abstraction->new(logger => sub { push @calls, $_[0] }, level => 'debug', ctx => 'C');
	my %fields = (user => 1);
	my $line = __LINE__; $logger->info('hello', \%fields);
	$fields{user} = 2;    # must not rewrite what was logged

	is(scalar(@calls), 1, 'called once');
	is($calls[0]{file}, __FILE__, 'file is this test');
	is($calls[0]{line}, $line, 'line is the logging call');
	is($calls[0]{ctx}, 'C', 'ctx passed on');
	is_deeply($calls[0]{fields}, { user => 1 }, 'fields were copied at log time');
	is_deeply($logger->messages(), [ { level => 'info', message => 'hello', fields => { user => 1 } } ], 'history has the fields');
};

subtest '_log() - per-backend levels and max_messages' => sub {
	# The backend's own level narrows; the history still sees everything
	my @errors;
	my $logger = Log::Abstraction->new(
		logger       => { array => { array => \@errors, level => 'error' } },
		level        => 'debug',
		max_messages => 2,
	);
	$logger->debug('d');
	$logger->error('e');
	$logger->info('i');
	is_deeply([ map { $_->{message} } @errors ], ['e'], 'the error-only backend saw only the error');
	is_deeply([ map { $_->{message} } @{$logger->messages()} ], [qw(e i)], 'history keeps only the newest max_messages');
};

subtest '_log() - journald backend builds fields for _journald_send' => sub {
	my @sent;
	my $g = mock_scoped 'Log::Abstraction::_journald_send' => sub { my ($self, $path, %f) = @_; push @sent, [ $path, \%f ] };
	my $logger = Log::Abstraction->new(
		logger => { journald => { socket => '/fake/socket', identifier => 'ident', extra_key => 'v' } },
		level  => 'debug',
	);
	$logger->warn('careful', { 'user id' => 7, MESSAGE => 'forged' });

	is(scalar(@sent), 1, 'one send');
	my ($path, $f) = @{$sent[0]};
	vdiag(explain($f));
	is($path, '/fake/socket', 'configured socket used');
	is($f->{MESSAGE}, 'careful', 'MESSAGE is the message; a field cannot replace it');
	is($f->{PRIORITY}, $LEVEL{warning}, 'PRIORITY is the syslog number');
	is($f->{SYSLOG_IDENTIFIER}, 'ident', 'identifier used');
	is($f->{EXTRA_KEY}, 'v', 'extra config keys upper-cased');
	is($f->{USER_ID}, 7, 'structured field names sanitised');
	ok(!exists($f->{SOCKET}) && !exists($f->{IDENTIFIER}), 'socket and identifier are not sent as fields');
};

subtest '_log() - syslog backend opens once and passes a %s format' => sub {
	my (@opened, @logged);
	my $g = mock_scoped(
		'Sys::Syslog::setlogsock' => sub { 1 },
		'Sys::Syslog::openlog'    => sub { push @opened, [@_]; 1 },
		'Sys::Syslog::syslog'     => sub { push @logged, [@_]; 1 },
		'Sys::Syslog::closelog'   => sub { 1 },
	);
	my $logger = Log::Abstraction->new(logger => { syslog => { type => 'unix' } }, level => 'debug');
	$logger->error('100%m sure');
	$logger->notice('second');
	is(scalar(@opened), 1, 'openlog called once');
	like($logged[0][0], qr/^err\|/, 'error maps to err (with the facility)');
	is_deeply([ @{$logged[0]}[1, 2] ], [ '%s', '100%m sure' ], 'message passed as data, so %m is literal');
	like($logged[1][0], qr/^notice\|/, 'notice maps to notice');
	undef $logger;
};

# ============================================================
# 36. _high_priority() - warn/error/critical argument handling
# ============================================================
subtest '_high_priority() - argument forms' => sub {
	my ($logger, $log) = array_logger();
	$logger->warn(warning => 'named');
	$logger->warn({ warning => [ 'a', undef, 'b' ] });
	$logger->warn('list', ' form');
	$logger->warn('with fields', { k => 1 });
	is_deeply([ map { $_->{message} } @{$log} ], [ 'named', 'ab', 'list form', 'with fields' ], 'each form gives the right text');
	is_deeply($log->[3]{fields}, { k => 1 }, 'trailing hashref became fields');
	is($logger->warn(), $logger, 'no arguments: nothing logged, still chainable');
	is(scalar(@{$log}), 4, 'nothing extra logged');
};

subtest '_high_priority() - class-method calls and no backend' => sub {
	my @carped;
	my $g = mock_scoped 'Carp::carp' => sub { push @carped, join('', @_) };
	Log::Abstraction->warn('class warn');
	is_deeply(\@carped, ['class warn'], 'class-method warn carps');
	throws_ok(sub { Log::Abstraction->error('class error') }, qr/^class error at /, 'class-method error croaks');

	# A logger with no backend must not lose errors silently
	my $bare = bless({ level => $LEVEL{debug}, messages => [] }, 'Log::Abstraction');
	throws_ok(sub { $bare->critical('nowhere') }, qr/^nowhere at /, 'no backend: critical croaks');
};

subtest 'critical(), alert(), emergency() - levels and croak_on_error' => sub {
	for my $method (qw(critical alert emergency)) {
		my ($logger, $log) = array_logger();
		is($logger->$method("$method msg"), $logger, "$method returns \$self");
		is($log->[0]{level}, $method, "$method logged at its own level");

		my $croaker = Log::Abstraction->new(array => [], croak_on_error => 1);
		throws_ok(sub { $croaker->$method('fatal') }, qr/^fatal at /, "$method croaks with croak_on_error");
	}
};

# ============================================================
# 37. Global state - logging must not disturb $_, $@ or $!
# ============================================================
# Callers log inside error handlers: eval { ... }; if($@) { $log->debug(...);
# die $@ }.  Every entry point must leave the caller's globals alone, and
# that includes the backends' own evals and I/O.
subtest 'logging preserves $_, $@ and $!' => sub {
	my $path = File::Spec->catfile($TMPDIR, 'globals.log');
	my $g = mock_scoped 'Log::Abstraction::_journald_send' => sub { $@ = 'inner'; $! = 1; die "no journal\n" };
	my $logger = Log::Abstraction->new(
		file   => $path,
		logger => { array => [], journald => {} },
		format => 'json',
		level  => 'debug',
	);
	local $SIG{__WARN__} = sub { };

	for my $method (qw(trace debug info notice warn error critical alert emergency)) {
		local $_ = $config{marker};
		eval { die "original\n" };
		$! = 2;
		my $errno = $! + 0;

		$logger->$method('message', { field => [1] });
		is($_, $config{marker}, "$method keeps \$_");
		is($@, "original\n", "$method keeps \$\@");
		is($! + 0, $errno, "$method keeps \$!");
	}
};

subtest 'DESTROY preserves $@ while closing syslog' => sub {
	my $g = mock_scoped 'Sys::Syslog::closelog' => sub { eval { die "closing\n" }; 1 };
	my $logger = bless({ level => $LEVEL{debug}, messages => [], _syslog_opened => 1 }, 'Log::Abstraction');
	eval { die "original\n" };
	undef $logger;
	is($@, "original\n", 'DESTROY did not clobber $@');
};

# ============================================================
# 38. level(), is_*() and messages() - return values
# ============================================================
subtest 'level() - getter type, chaining, case' => sub {
	my ($logger) = array_logger();
	returns_ok($logger->level(), { type => 'integer', min => 0, max => $LEVEL{debug} }, 'getter returns 0-7');
	is($logger->level('ERROR'), $logger, 'setter returns $self');
	is($logger->level(), $LEVEL{error}, 'names are case-insensitive');
};

subtest 'is_*() - follow the threshold' => sub {
	my %method_level = (
		trace => 'debug', debug => 'debug', info => 'info', notice => 'notice', warn => 'warning',
		error => 'error', critical => 'critical', alert => 'alert', emergency => 'emergency',
	);
	for my $threshold (sort keys %LEVEL) {
		my $logger = Log::Abstraction->new(array => [], level => $threshold);
		for my $method (sort keys %method_level) {
			my $want = ($LEVEL{$method_level{$method}} <= $LEVEL{$threshold}) ? 1 : 0;
			is($logger->${\"is_$method"}(), $want, "is_$method at level $threshold");
		}
	}
};

subtest 'messages() - arrayref copy' => sub {
	my ($logger) = array_logger();
	$logger->info('one');
	my $copy = $logger->messages();
	returns_ok($copy, { type => 'arrayref' }, 'returns an arrayref');
	push @{$copy}, 'junk';
	is(scalar(@{$logger->messages()}), 1, 'changing the copy leaves the history alone');
};

# ============================================================
# 39. Memory - no cycles, objects are freed
# ============================================================
subtest 'no memory cycles; loggers and clones are freed' => sub {
	my $path = File::Spec->catfile($TMPDIR, 'memory.log');
	my $logger = Log::Abstraction->new(
		file   => $path,
		logger => { array => [] },
		array  => [],
		level  => 'debug',
	);
	$logger->info('one', { f => { nested => [1] } });
	$logger->warn('two');
	my $clone = $logger->new(level => 'info');
	$clone->info('three');

	memory_cycle_ok($logger, 'logger has no cycles after logging');
	memory_cycle_ok($clone, 'clone has no cycles');

	my $weak_logger = $logger;
	my $weak_clone  = $clone;
	weaken($weak_logger);
	weaken($weak_clone);
	undef $logger;
	undef $clone;
	ok(!defined($weak_logger), 'logger freed');
	ok(!defined($weak_clone), 'clone freed');
};

# ============================================================
# 40. Log::Any::Adapter::Abstraction
# ============================================================
SKIP: {
	skip('Log::Any not installed', 1) unless(eval { require Log::Any::Adapter::Abstraction; 1 });

	subtest 'adapter init() - instance, bad instance, built from arguments' => sub {
		my ($la) = array_logger();
		my $adapter = Log::Any::Adapter::Abstraction->new(instance => $la);
		is($adapter->{_logger}, $la, 'given instance is wrapped');

		throws_ok(
			sub { Log::Any::Adapter::Abstraction->new(instance => bless({}, 'Other')) },
			qr/^\QLog::Any::Adapter::Abstraction: instance must be a Log::Abstraction object\E at /,
			'non-Log::Abstraction instance rejected'
		);

		my @log;
		my $built = Log::Any::Adapter::Abstraction->new(array => \@log, level => 'info', ignored => 1);
		isa_ok($built->{_logger}, 'Log::Abstraction');
		is($built->{_logger}->level(), $LEVEL{info}, 'level passed through');
		memory_cycle_ok($built, 'adapter has no cycles');
	};

	subtest 'adapter logging methods - mapping, croak to carp, globals kept' => sub {
		my %map = (
			trace => 'trace', debug => 'debug', info => 'info', notice => 'notice', warning => 'warn',
			error => 'error', critical => 'critical', alert => 'alert', emergency => 'emergency',
		);
		my ($la) = array_logger();
		my $adapter = Log::Any::Adapter::Abstraction->new(instance => $la);
		for my $any (sort keys %map) {
			my @calls;
			my $g = mock_scoped "Log::Abstraction::$map{$any}" => sub { push @calls, [ @_[1 .. $#_] ]; return $_[0] };
			$adapter->$any('m');
			is_deeply(\@calls, [ ['m'] ], "$any calls Log::Abstraction::$map{$any}");
		}

		my $croaker = Log::Any::Adapter::Abstraction->new(instance => Log::Abstraction->new(array => [], croak_on_error => 1));
		my @carped;
		my $g = mock_scoped 'Carp::carp' => sub { push @carped, join('', @_) };
		# Called directly, not in lives_ok, whose own eval would reset $@
		eval { die "original\n" };
		$croaker->error('fatal');
		is($@, "original\n", "the caller's \$\@ survives");
		like($carped[0] // '', qr/^fatal at /, 'the croak was carped instead of escaping');
	};

	subtest 'adapter structured() - fields and parts' => sub {
		my ($la, $log) = array_logger();
		my $adapter = Log::Any::Adapter::Abstraction->new(instance => $la);
		$adapter->structured('warning', 'cat', 'a', undef, '', 'b', { k => 1 });
		$adapter->structured('info', 'cat', 'no fields');
		$adapter->structured('bogus', 'cat', 'ignored');
		is_deeply($log, [
			{ level => 'warn', message => 'a b', fields => { k => 1 } },
			{ level => 'info', message => 'no fields' },
		], 'parts joined with a space, empty parts dropped, unknown level ignored');
	};

	subtest 'adapter is_*() - delegate to the wrapped logger' => sub {
		my $la = Log::Abstraction->new(array => [], level => 'warning');
		my $adapter = Log::Any::Adapter::Abstraction->new(instance => $la);
		is($adapter->is_warning(), 1, 'is_warning uses is_warn');
		is($adapter->is_error(), 1, 'more severe level enabled');
		is($adapter->is_info(), 0, 'less severe level disabled');
		$la->level('debug');
		is($adapter->is_trace(), 1, 'follows changes to the wrapped level');
	};
}

done_testing();
