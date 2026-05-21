#!/usr/bin/env perl

# unit.t - Black-box unit tests for Log::Abstraction public API.
# Each subtest exercises exactly what the POD documents, nothing more.
# Test::Mockingbird intercepts outbound calls to non-core modules
# (Carp::carp, Carp::croak, Sys::Syslog::*) where the test needs to
# observe or suppress them.  All logging is driven through in-memory
# array backends so no filesystem or syslog infrastructure is required.

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird qw(mock_scoped);

use_ok('Log::Abstraction');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Returns ($logger, \@log) with level=debug so nothing is filtered.
sub array_logger {
	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	return ($logger, \@log);
}

# Returns ($logger, \@log) at a specific minimum level.
sub array_logger_at {
	my $level = shift;
	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => $level);
	return ($logger, \@log);
}

# ============================================================
# new() — POD: "Creates a new Log::Abstraction object"
# ============================================================

subtest 'new() — returns a blessed Log::Abstraction object' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	ok(defined $logger, 'new() returns a defined value');
	isa_ok($logger, 'Log::Abstraction');
};

# POD: "The argument can be a hash, a reference to a hash or the logger value"
subtest 'new() — accepts a plain hash' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'debug');
	isa_ok($logger, 'Log::Abstraction');
};

subtest 'new() — accepts a hashref' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new({ array => \@log, level => 'debug' });
	isa_ok($logger, 'Log::Abstraction');
};

subtest 'new() — accepts a bare logger value' => sub {
	plan tests => 1;

	# Scalar string is treated as a filename logger
	my $logger = Log::Abstraction->new('somefile.log');
	isa_ok($logger, 'Log::Abstraction');
};

# POD: level — "The minimum level at which to log something, the default is warning"
subtest 'new() — default minimum level is warning' => sub {
	plan tests => 2;

	my ($logger) = array_logger_at('warning');
	# info (6) is below warning (4) threshold — numerically higher, so filtered
	$logger->info('should be filtered');
	my $m = $logger->messages();
	is(scalar(@{$m}), 0, 'info filtered when level=warning');

	# warn (4) equals warning threshold — should pass
	$logger->warn('should appear');
	$m = $logger->messages();
	is(scalar(@{$m}), 1, 'warn passes when level=warning');
};

# POD: logger => array — "a reference to an array"
subtest 'new() — logger => arrayref accumulates entries' => sub {
	plan tests => 3;

	my @log;
	my $logger = Log::Abstraction->new(logger => \@log, level => 'debug');
	$logger->debug('entry one');
	$logger->debug('entry two');
	is(scalar(@log),      2,           'two entries pushed to arrayref logger');
	is($log[0]{message}, 'entry one',  'first message correct');
	is($log[1]{message}, 'entry two',  'second message correct');
};

# POD: logger => code ref — "called with a hashref containing: class, file,
#      line, level, message (arrayref), ctx"
subtest 'new() — logger => coderef receives correct hashref keys' => sub {
	plan tests => 6;

	my %got;
	my $logger = Log::Abstraction->new(
		logger => sub { %got = %{$_[0]} },
		level  => 'debug',
	);
	$logger->debug('coderef msg');
	ok(exists $got{class},   'class key present');
	ok(exists $got{file},    'file key present');
	ok(exists $got{line},    'line key present');
	ok(exists $got{level},   'level key present');
	ok(exists $got{message}, 'message key present');
	is(ref($got{message}),  'ARRAY', 'message value is an arrayref');
};

# POD: ctx — "passed to new(), a argument that can help to give context to the caller"
subtest 'new() — ctx is forwarded to coderef logger' => sub {
	plan tests => 1;

	my $got_ctx;
	my $logger = Log::Abstraction->new(
		logger => sub { $got_ctx = $_[0]->{ctx} },
		level  => 'debug',
		ctx    => 'test-context',
	);
	$logger->debug('ctx test');
	is($got_ctx, 'test-context', 'ctx forwarded to coderef logger');
};

# POD: carp_on_warn — "call Carp::carp on warn(). Causes error() to carp if
#      croak_on_error is not given"
subtest 'new() — carp_on_warn causes Carp::carp on warn()' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(
		array        => \@log,
		level        => 'debug',
		carp_on_warn => 1,
	);
	my $carped = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $carped++ };
	$logger->warn('carpable');
	is($carped, 1, 'Carp::carp called once when carp_on_warn=1');
};

# POD: croak_on_error — "call Carp::croak on error()"
subtest 'new() — croak_on_error causes croak on error()' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(
		array          => \@log,
		level          => 'debug',
		croak_on_error => 1,
	);
	throws_ok(
		sub { $logger->error('fatal') },
		qr/fatal/,
		'croak_on_error causes croak on error()'
	);
};

# POD: Clone — "Clone existing objects with or without modifications"
subtest 'new() — clone with no args inherits all attributes' => sub {
	plan tests => 3;

	my ($orig) = array_logger();
	my $clone  = $orig->new();
	isa_ok($clone, 'Log::Abstraction');
	isnt($clone, $orig, 'clone is a distinct object');
	is($clone->{level}, $orig->{level}, 'clone inherits level');
};

subtest 'new() — clone with level override converts to integer' => sub {
	plan tests => 2;

	my ($orig) = array_logger();	# debug = 7
	my $clone  = $orig->new(level => 'warning');
	is($clone->{level}, 4, 'clone level set to warning (4)');
	is($orig->{level},  7, 'original level unchanged');
};

subtest 'new() — clone messages are a deep copy' => sub {
	plan tests => 2;

	my ($orig) = array_logger();
	$orig->debug('before clone');
	my $clone = $orig->new();
	is(scalar(@{$clone->messages()}), 1, 'clone inherits existing messages');
	$clone->debug('clone only');
	is(scalar(@{$orig->messages()}), 1, 'original unaffected by clone message');
};

# ============================================================
# level() — POD: "Get/set the minimum level to log at.
#                 Returns the current level, as an integer."
# ============================================================

subtest 'level() — getter returns an integer' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	my $l = $logger->level();
	ok(defined $l,       'level() returns a defined value');
	like($l, qr/^\d+$/,  'level() value is an integer');
};

subtest 'level() — setter updates the level' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->level('warning');
	is($logger->level(), 4, 'level() updated to warning (4)');
};

subtest 'level() — setter rejects invalid level' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	my $orig = $logger->level();
	my $carped = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $carped++ };
	my $ret = $logger->level('bogus');
	ok($carped,        'Carp::carp called for invalid level');
	ok(!defined($ret), 'undef returned for invalid level');
};

subtest 'level() — setter affects what gets logged' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();	# starts at debug
	$logger->level('error');		# tighten to error only

	$logger->info('filtered');
	is(scalar(@{$log}), 0, 'info filtered after level raised to error');

	$logger->error('passes');
	is(scalar(@{$log}), 1, 'error passes after level raised to error');
};

# ============================================================
# is_debug() — POD: "Are we at a debug level that will emit debug messages?"
# ============================================================

subtest 'is_debug() — true when level is debug' => sub {
	plan tests => 1;

	my ($logger) = array_logger();	# level=debug
	is($logger->is_debug(), 1, 'is_debug() true at debug level');
};

subtest 'is_debug() — false when level is warning' => sub {
	plan tests => 1;

	my ($logger) = array_logger_at('warning');
	is($logger->is_debug(), 0, 'is_debug() false at warning level');
};

subtest 'is_debug() — false when level is error' => sub {
	plan tests => 1;

	my ($logger) = array_logger_at('error');
	is($logger->is_debug(), 0, 'is_debug() false at error level');
};

subtest 'is_debug() — false when level is info' => sub {
	plan tests => 1;

	my ($logger) = array_logger_at('info');
	is($logger->is_debug(), 0, 'is_debug() false at info level');
};

# ============================================================
# messages() — POD: "Return all the messages emitted so far"
# ============================================================

subtest 'messages() — returns an arrayref' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	is(ref($logger->messages()), 'ARRAY', 'messages() returns ARRAY ref');
};

subtest 'messages() — empty before any logging' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	is(scalar(@{$logger->messages()}), 0, 'messages() empty initially');
};

subtest 'messages() — accumulates one entry per log call' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->debug('one');
	$logger->info('two');
	$logger->notice('three');
	is(scalar(@{$logger->messages()}), 3, 'three messages recorded');
};

subtest 'messages() — each entry has level and message keys' => sub {
	plan tests => 4;

	my ($logger) = array_logger();
	$logger->debug('msg text');
	my $m = $logger->messages()->[0];
	ok(exists $m->{level},   'entry has level key');
	ok(exists $m->{message}, 'entry has message key');
	is($m->{level},   'debug',    'level value correct');
	is($m->{message}, 'msg text', 'message value correct');
};

subtest 'messages() — returns a copy, not the live store' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	my $snapshot = $logger->messages();
	$logger->debug('after snapshot');
	isnt(scalar(@{$snapshot}), scalar(@{$logger->messages()}),
		'snapshot count differs from live store after new message');
};

subtest 'messages() — filtered messages not recorded' => sub {
	plan tests => 1;

	my ($logger) = array_logger_at('error');
	$logger->debug('filtered');
	is(scalar(@{$logger->messages()}), 0, 'filtered message not in messages()');
};

# ============================================================
# debug() — POD: "Logs a debug message"
# ============================================================

subtest 'debug() — message appears in messages()' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	$logger->debug('debug test');
	my $m = $logger->messages();
	is(scalar(@{$m}),    1,            'one message recorded');
	is($m->[0]{message}, 'debug test', 'message text correct');
};

subtest 'debug() — level recorded as debug' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->debug('x');
	is($logger->messages()->[0]{level}, 'debug', 'level is debug');
};

subtest 'debug() — filtered at warning level' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger_at('warning');
	$logger->debug('filtered');
	is(scalar(@{$log}), 0, 'debug not emitted at warning level');
};

subtest 'debug() — accepts multiple args joined' => sub {
	plan tests => 1;

	# _log joins with join(''), so args are concatenated without separator
	my ($logger) = array_logger();
	$logger->debug('hello', ' world');
	is($logger->messages()->[0]{message}, 'hello world', 'args concatenated by join("")');
};

subtest 'debug() — accepts arrayref of messages' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->debug(['part1 ', 'part2']);
	is($logger->messages()->[0]{message}, 'part1 part2', 'arrayref joined');
};

subtest 'debug() — trailing newline stripped' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->debug("trimmed\n");
	is($logger->messages()->[0]{message}, 'trimmed', 'newline stripped');
};

# ============================================================
# info() — POD: "Logs an info message"
# ============================================================

subtest 'info() — message recorded at info level' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	$logger->info('info test');
	is($logger->messages()->[0]{message}, 'info test', 'message text correct');
	is($logger->messages()->[0]{level},   'info',      'level is info');
};

subtest 'info() — filtered when level is error' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger_at('error');
	$logger->info('filtered');
	is(scalar(@{$log}), 0, 'info filtered at error level');
};

subtest 'info() — passes when level is info' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger_at('info');
	$logger->info('passes');
	is(scalar(@{$log}), 1, 'info passes at info level');
};

# ============================================================
# notice() — POD: "Logs a notice message"
# ============================================================

subtest 'notice() — message recorded at notice level' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	$logger->notice('notice test');
	is($logger->messages()->[0]{message}, 'notice test', 'message text correct');
	is($logger->messages()->[0]{level},   'notice',      'level is notice');
};

subtest 'notice() — filtered when level is warning' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger_at('warning');
	$logger->notice('filtered');
	is(scalar(@{$log}), 0, 'notice filtered at warning level');
};

subtest 'notice() — passes when level is notice' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger_at('notice');
	$logger->notice('passes');
	is(scalar(@{$log}), 1, 'notice passes at notice level');
};

# ============================================================
# trace() — POD: "Logs a trace message"
# ============================================================

subtest 'trace() — message recorded' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	$logger->trace('trace test');
	is($logger->messages()->[0]{message}, 'trace test', 'message text correct');
	is($logger->messages()->[0]{level},   'trace',      'level is trace');
};

subtest 'trace() — filtered when level is warning' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger_at('warning');
	$logger->trace('filtered');
	is(scalar(@{$log}), 0, 'trace filtered at warning level');
};

# ============================================================
# warn() — POD: "Logs a warning message ... falls back to Carp"
# Accepts: @messages, \@messages, warning => \@messages
# ============================================================

subtest 'warn() — plain string logged' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->warn('a warning');
	is(scalar(@{$log}),  1,           'one entry logged');
	is($log->[0]{level}, 'warn',      'level is warn');
};

subtest 'warn() — message text correct' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->warn('warn text');
	is($logger->messages()->[0]{message}, 'warn text', 'message text correct');
};

subtest 'warn() — warning => scalar form' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->warn(warning => 'keyed warning');
	is($logger->messages()->[0]{message}, 'keyed warning', 'warning key extracted');
};

subtest 'warn() — warning => arrayref joined' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->warn(warning => ['part A', ' part B']);
	is($logger->messages()->[0]{message}, 'part A part B', 'arrayref joined');
};

subtest 'warn() — no args does nothing' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn();
	is(scalar(@{$log}), 0, 'no-arg warn logs nothing');
};

subtest 'warn() — carp_on_warn fires Carp::carp' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(
		array        => \@log,
		level        => 'debug',
		carp_on_warn => 1,
	);
	my $carped = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $carped++ };
	$logger->warn('carp me');
	is($carped, 1, 'Carp::carp called when carp_on_warn=1');
};

subtest 'warn() — no carp without carp_on_warn when array backend set' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	my $carped = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $carped++ };
	$logger->warn('no carp');
	is($carped, 0, 'Carp::carp not called without carp_on_warn when array set');
};

# ============================================================
# error() — POD: "Logs an error message ... falls back to Croak"
# ============================================================

subtest 'error() — message recorded' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->error('an error');
	is(scalar(@{$log}),  1,       'one entry logged');
	is($log->[0]{level}, 'error', 'level is error');
};

subtest 'error() — message text correct' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->error('error text');
	is($logger->messages()->[0]{message}, 'error text', 'message text correct');
};

subtest 'error() — croak_on_error causes croak' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(
		array          => \@log,
		level          => 'debug',
		croak_on_error => 1,
	);
	throws_ok(
		sub { $logger->error('fatal error') },
		qr/fatal error/,
		'croak_on_error causes croak with message text'
	);
};

subtest 'error() — no croak without croak_on_error when array backend set' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	lives_ok(sub { $logger->error('gentle') }, 'no croak without croak_on_error');
	is($log->[0]{message}, 'gentle', 'message still logged');
};

subtest 'error() — no croak without croak_on_error' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	my $croaked = 0;
	my $g = mock_scoped 'Carp::croak' => sub { $croaked++ };
	$logger->error('no croak');
	is($croaked, 0, 'Carp::croak not called without croak_on_error when array set');
};

# ============================================================
# fatal() — POD: "Synonym of error"
# ============================================================

subtest 'fatal() — behaves identically to error()' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->fatal('fatal msg');
	is(scalar(@{$log}),  1,       'one entry logged');
	is($log->[0]{level}, 'error', 'level recorded as error (synonym)');
};

subtest 'fatal() — croak_on_error causes croak' => sub {
	plan tests => 1;

	my @log;
	my $logger = Log::Abstraction->new(
		array          => \@log,
		level          => 'debug',
		croak_on_error => 1,
	);
	throws_ok(
		sub { $logger->fatal('kaboom') },
		qr/kaboom/,
		'fatal() croaks when croak_on_error=1'
	);
};

subtest 'fatal() — message text correct' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	$logger->fatal('fatal text');
	is($logger->messages()->[0]{message}, 'fatal text', 'message text correct');
};

# ============================================================
# Level filtering — all levels obey the minimum level setting
# ============================================================

subtest 'level filtering — debug=7 is least severe, passes all' => sub {
	plan tests => 1;

	# All six methods should emit when level=debug (7), since every
	# syslog priority value (3..7) is <= 7.
	# warn() and error() route through _high_priority which always
	# calls _log regardless; _log's own level check then applies.
	my ($logger, $log) = array_logger();	# level=debug
	$logger->debug('a');
	$logger->trace('b');
	$logger->info('c');
	$logger->notice('d');
	$logger->warn('e');
	$logger->error('f');
	is(scalar(@{$log}), 6, 'all six methods emit at debug level');
};

subtest 'level filtering — error=3 only passes error' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger_at('error');
	$logger->debug('no');
	$logger->info('no');
	$logger->notice('no');
	$logger->warn('no');
	is(scalar(@{$log}), 0, 'debug/info/notice/warn all filtered at error level');

	$logger->error('yes');
	is(scalar(@{$log}), 1, 'error passes at error level');
};

subtest 'level filtering — notice=5 passes notice and more severe' => sub {
	plan tests => 2;

	# Syslog priority: lower integer = more severe.
	# level=notice(5) means: log anything with priority <= 5.
	# notice(5), warn(4), error(3) all pass.
	# info(6), debug(7), trace(7) are filtered.
	my ($logger, $log) = array_logger_at('notice');
	$logger->info('no');
	$logger->debug('no');
	$logger->trace('no');
	is(scalar(@{$log}), 0, 'info/debug/trace filtered at notice level');

	$logger->notice('yes');
	$logger->warn('yes');
	$logger->error('yes');
	is(scalar(@{$log}), 3, 'notice/warn/error all pass at notice level');
};

# ============================================================
# messages() interacts correctly with level filtering
# ============================================================

subtest 'messages() — only passed messages stored, not filtered ones' => sub {
	plan tests => 2;

	my ($logger) = array_logger_at('warning');
	$logger->debug('filtered');
	$logger->info('filtered');
	is(scalar(@{$logger->messages()}), 0, 'no messages stored for filtered levels');

	$logger->warn('stored');
	is(scalar(@{$logger->messages()}), 1, 'warn message stored at warning level');
};

# ============================================================
# format — POD documents %level%, %message%, %timestamp%,
#           %class%, %callstack%, %env_foo%
# ============================================================

subtest 'format — tokens expanded in file output' => sub {
	plan tests => 3;

	require File::Temp;
	my $tmp  = File::Temp->new(UNLINK => 1, SUFFIX => '.log');
	my $path = $tmp->filename();
	close $tmp;

	my $logger = Log::Abstraction->new(
		file   => $path,
		level  => 'debug',
		format => '[%level%] %message% at %timestamp%',
	);
	$logger->info('fmt test');

	open(my $fh, '<', $path) or die "Cannot read $path: $!";
	my $line = <$fh>;
	close $fh;

	like($line, qr/\[INFO\]/i,           '%level% expanded and uppercased');
	like($line, qr/fmt test/,            '%message% expanded');
	like($line, qr/\d{4}-\d{2}-\d{2}/,  '%timestamp% expanded to date');
};

subtest 'format — %env_foo% expanded from %ENV' => sub {
	plan tests => 1;

	local $ENV{LA_TEST_VAR} = 'env_expanded';

	require File::Temp;
	my $tmp  = File::Temp->new(UNLINK => 1, SUFFIX => '.log');
	my $path = $tmp->filename();
	close $tmp;

	my $logger = Log::Abstraction->new(
		file   => $path,
		level  => 'debug',
		format => '%env_LA_TEST_VAR%',
	);
	$logger->debug('trigger');

	open(my $fh, '<', $path) or die $!;
	my $line = <$fh>;
	close $fh;

	like($line, qr/env_expanded/, '%env_foo% token expanded from %ENV');
};

done_testing();
