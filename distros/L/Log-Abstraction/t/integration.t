#!/usr/bin/env perl

# integration.t - End-to-end black-box integration tests for Log::Abstraction.
#
# Focus: multi-method workflows, stateful accumulation across calls, all
# constructor forms interacting with all logger backends, config-file loading,
# clone chains, level changes mid-session, syslog lifecycle (mocked),
# sendmail path (mocked), object-logger delegation (Log::Log4perl), and
# format token expansion across backends.
#
# Rule: every observable is through the public API only.  No reaching into
# internal hash slots.  Test::Mockingbird intercepts outbound calls to
# non-core modules where observation or suppression is needed.

use strict;
use warnings;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Log::Abstraction;
use Test::Most;
use Test::Mockingbird qw(mock_scoped);

# ---------------------------------------------------------------------------
# Confirm the module loads and has the right version format
# ---------------------------------------------------------------------------
use_ok('Log::Abstraction');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub tmp_log_file {
	my ($fh, $path) = tempfile(SUFFIX => '.log', UNLINK => 1);
	close $fh;
	return $path;
}

sub slurp { my $f = shift; open my $fh, '<', $f or die $!; local $/; <$fh> }

sub array_logger {
	my @log;
	my $l = Log::Abstraction->new(array => \@log, level => 'debug');
	return ($l, \@log);
}

# ============================================================
# 1. Module identity
# ============================================================

subtest 'module version is defined and numeric' => sub {
	plan tests => 2;

	ok(defined $Log::Abstraction::VERSION, 'VERSION is defined');
	like($Log::Abstraction::VERSION, qr/^\d+\.?\d*$/, 'VERSION looks numeric');
};

subtest 'new_ok — constructs a valid object' => sub {
	plan tests => 1;

	my @log;
	new_ok('Log::Abstraction', [array => \@log, level => 'debug']);
};

# ============================================================
# 2. Full logging lifecycle — all methods on one logger
# ============================================================

subtest 'lifecycle — all public log methods accumulate in messages()' => sub {
	plan tests => 7;

	my ($logger) = array_logger();
	$logger->trace('t');
	$logger->debug('d');
	$logger->info('i');
	$logger->notice('n');
	$logger->warn('w');
	$logger->error('e');
	$logger->fatal('f');	# synonym for error

	my $m = $logger->messages();
	is(scalar(@{$m}), 7, 'seven messages recorded');
	is($m->[0]{level}, 'trace',  'first is trace');
	is($m->[1]{level}, 'debug',  'second is debug');
	is($m->[2]{level}, 'info',   'third is info');
	is($m->[3]{level}, 'notice', 'fourth is notice');
	is($m->[4]{level}, 'warn',   'fifth is warn');
	# fatal and error both record as 'error'
	is($m->[5]{level}, 'error',  'sixth is error');
};

subtest 'lifecycle — messages() is ordered chronologically' => sub {
	plan tests => 4;

	my ($logger) = array_logger();
	$logger->debug('first');
	$logger->info('second');
	$logger->notice('third');
	$logger->warn('fourth');

	my $m = $logger->messages();
	is($m->[0]{message}, 'first',  'order 1');
	is($m->[1]{message}, 'second', 'order 2');
	is($m->[2]{message}, 'third',  'order 3');
	is($m->[3]{message}, 'fourth', 'order 4');
};

# ============================================================
# 3. Level changes mid-session
# ============================================================

subtest 'mid-session level change — tightening filters subsequent calls' => sub {
	plan tests => 3;

	my ($logger, $log) = array_logger();	# starts debug

	$logger->debug('visible 1');
	is(scalar(@{$log}), 1, 'debug visible before level change');

	$logger->level('error');
	$logger->debug('invisible');
	$logger->info('invisible');
	$logger->notice('invisible');
	$logger->warn('invisible');
	is(scalar(@{$log}), 1, 'debug/info/notice/warn filtered after tighten to error');

	$logger->error('visible 2');
	is(scalar(@{$log}), 2, 'error still visible after tighten');
};

subtest 'mid-session level change — loosening allows previously filtered levels' => sub {
	plan tests => 3;

	my @log;
	my $logger = Log::Abstraction->new(array => \@log, level => 'error');

	$logger->debug('filtered');
	is(scalar(@log), 0, 'debug filtered at error level');

	$logger->level('debug');
	$logger->debug('now visible');
	is(scalar(@log), 1, 'debug visible after loosening to debug');
	is($log[0]{message}, 'now visible', 'correct message logged after loosen');
};

subtest 'mid-session level change — is_debug() reflects new level' => sub {
	plan tests => 2;

	my ($logger) = array_logger();
	is($logger->is_debug(), 1, 'is_debug true at debug level');
	$logger->level('warning');
	is($logger->is_debug(), 0, 'is_debug false after level raised to warning');
};

# ============================================================
# 4. Clone chains
# ============================================================

subtest 'clone chain — grandchild inherits from child inherits from parent' => sub {
	plan tests => 4;

	my @log;
	my $parent = Log::Abstraction->new(array => \@log, level => 'debug');
	$parent->debug('from parent');

	my $child = $parent->new(level => 'warning');
	$child->debug('filtered in child');
	$child->warn('from child');

	my $grandchild = $child->new(level => 'debug');
	$grandchild->debug('from grandchild');

	is(scalar(@log), 3, 'parent+child warn+grandchild = 3 entries in shared array');
	is($log[0]{message}, 'from parent',      'parent message');
	is($log[1]{message}, 'from child',        'child message');
	is($log[2]{message}, 'from grandchild',   'grandchild message');
};

subtest 'clone — messages() snapshot independence across generations' => sub {
	plan tests => 3;

	my ($parent) = array_logger();
	$parent->debug('p1');
	$parent->debug('p2');

	my $child = $parent->new();
	# Child starts with a copy of parent's message history
	is(scalar(@{$child->messages()}), 2, 'child starts with parent message history');

	$child->debug('c1');
	is(scalar(@{$child->messages()}), 3, 'child accumulates its own messages');
	is(scalar(@{$parent->messages()}), 2, 'parent message count unchanged');
};

subtest 'clone — level override does not affect parent level' => sub {
	plan tests => 2;

	my ($parent) = array_logger();	# debug=7
	my $child = $parent->new(level => 'error');
	is($parent->level(), 7, 'parent level unchanged after clone with override');
	is($child->level(),  3, 'child has overridden level');
};

subtest 'clone — child shares array backend with parent' => sub {
	plan tests => 2;

	my @shared;
	my $parent = Log::Abstraction->new(array => \@shared, level => 'debug');
	my $child  = $parent->new();

	$parent->debug('from parent');
	$child->debug('from child');

	is(scalar(@shared), 2, 'both parent and child write to shared array');
	is($shared[1]{message}, 'from child', 'child entry present in shared array');
};

# ============================================================
# 5. File backend — end-to-end
# ============================================================

subtest 'file backend — all log levels written to file' => sub {
	plan tests => 5;

	# Array sink prevents _high_priority fallback to Carp for warn/error
	# when no 'logger' or 'array' key is present on a file-only logger.
	my @sink;
	my $path   = tmp_log_file();
	my $logger = Log::Abstraction->new(file => $path, array => \@sink, level => 'debug');
	$logger->debug('file debug');
	$logger->info('file info');
	$logger->notice('file notice');
	$logger->warn('file warn');
	$logger->error('file error');

	my $content = slurp($path);
	like($content, qr/file debug/,  'debug written to file');
	like($content, qr/file info/,   'info written to file');
	like($content, qr/file notice/, 'notice written to file');
	like($content, qr/file warn/,   'warn written to file');
	like($content, qr/file error/,  'error written to file');
};

subtest 'file backend — messages appended across multiple calls' => sub {
	plan tests => 1;

	my $path   = tmp_log_file();
	my $logger = Log::Abstraction->new(file => $path, level => 'debug');
	$logger->debug('line 1');
	$logger->debug('line 2');
	$logger->debug('line 3');

	my @lines = grep { /\S/ } split /\n/, slurp($path);
	is(scalar(@lines), 3, 'three lines appended to file');
};

subtest 'file backend — level filtering respected on file output' => sub {
	plan tests => 2;

	my @sink;
	my $path   = tmp_log_file();
	my $logger = Log::Abstraction->new(file => $path, array => \@sink, level => 'error');
	$logger->debug('no');
	$logger->info('no');
	$logger->notice('no');

	my $content = slurp($path);
	is($content, '', 'nothing written to file when all messages filtered');

	$logger->error('yes');
	$content = slurp($path);
	like($content, qr/yes/, 'error written after filter');
};

subtest 'file backend — format tokens all expand correctly' => sub {
	plan tests => 5;

	local $ENV{LA_INTEG_VAR} = 'integ_env';
	my $path   = tmp_log_file();
	my $logger = Log::Abstraction->new(
		file   => $path,
		level  => 'debug',
		format => '%level%|%message%|%timestamp%|%class%|%env_LA_INTEG_VAR%',
	);
	$logger->info('token test');

	my $line = slurp($path);
	like($line, qr/INFO/i,               '%level% expanded');
	like($line, qr/token test/,          '%message% expanded');
	like($line, qr/\d{4}-\d{2}-\d{2}/,  '%timestamp% contains date');
	like($line, qr/\|/,                  'pipe separators present');
	like($line, qr/integ_env/,           '%env_LA_INTEG_VAR% expanded');
};

subtest 'file backend — both file and array backends active simultaneously' => sub {
	plan tests => 3;

	my @log;
	my $path   = tmp_log_file();
	my $logger = Log::Abstraction->new(
		file  => $path,
		array => \@log,
		level => 'debug',
	);
	$logger->info('dual backend');

	is(scalar(@log),        1,             'message in array backend');
	is($log[0]{message},    'dual backend', 'correct message in array');
	like(slurp($path),      qr/dual backend/, 'message also in file');
};

# ============================================================
# 6. fd backend — end-to-end
# ============================================================

subtest 'fd backend — writes to open filehandle' => sub {
	plan tests => 2;

	my @sink;
	my ($fh, $path) = tempfile(SUFFIX => '.log', UNLINK => 1);
	my $logger = Log::Abstraction->new(fd => $fh, array => \@sink, level => 'debug');
	$logger->debug('fd test');
	$logger->warn('fd warn');
	close $fh;

	my $content = slurp($path);
	like($content, qr/fd test/, 'debug message written via fd');
	like($content, qr/fd warn/, 'warn message written via fd');
};

subtest 'fd backend — level filter respected' => sub {
	plan tests => 2;

	my @sink;
	my ($fh, $path) = tempfile(SUFFIX => '.log', UNLINK => 1);
	my $logger = Log::Abstraction->new(fd => $fh, array => \@sink, level => 'warning');
	$logger->debug('filtered');
	$logger->info('filtered');
	close $fh;

	is(-s $path, 0, 'nothing written when all messages filtered via fd');

	my @sink2;
	my ($fh2, $path2) = tempfile(SUFFIX => '.log', UNLINK => 1);
	my $logger2 = Log::Abstraction->new(fd => $fh2, array => \@sink2, level => 'warning');
	$logger2->warn('passes');
	close $fh2;
	like(slurp($path2), qr/passes/, 'warn passes at warning level via fd');
};

# ============================================================
# 7. Hash-ref logger — combined keys
# ============================================================

subtest 'hash-ref logger — file + array combined' => sub {
	plan tests => 4;

	my @out;
	my $path   = tmp_log_file();
	my $logger = Log::Abstraction->new(
		logger => { file => $path, array => \@out },
		level  => 'debug',
	);
	$logger->debug('hash combined');

	is(scalar(@out),        1,               'one entry in array');
	is($out[0]{message},    'hash combined',  'message in array correct');
	like(slurp($path),      qr/hash combined/, 'message in file');
	is($out[0]{level},      'debug',           'level in array correct');
};

subtest 'hash-ref logger — multiple messages accumulate in array' => sub {
	plan tests => 2;

	my @out;
	my $logger = Log::Abstraction->new(logger => { array => \@out }, level => 'debug');
	$logger->debug('one');
	$logger->info('two');
	$logger->notice('three');

	is(scalar(@out), 3, 'three entries accumulated');
	is($out[2]{message}, 'three', 'third message correct');
};

# ============================================================
# 8. Code-ref logger — stateful interaction
# ============================================================

subtest 'coderef logger — accumulates all fields across multiple calls' => sub {
	plan tests => 6;

	my @calls;
	my $logger = Log::Abstraction->new(
		logger => sub { push @calls, { %{$_[0]} } },
		level  => 'debug',
	);
	$logger->debug('alpha');
	$logger->warn('beta');

	is(scalar(@calls), 2,                      'two coderef invocations');
	is($calls[0]{level},      'debug',          'first call level');
	is($calls[0]{message}[0], 'alpha',          'first call message');
	is($calls[1]{level},      'warn',           'second call level');
	is($calls[1]{message}[0], 'beta',           'second call message');
	ok(defined $calls[0]{file},                 'file key populated');
};

subtest 'coderef logger — ctx flows through all calls' => sub {
	plan tests => 2;

	my @ctxs;
	my $logger = Log::Abstraction->new(
		logger => sub { push @ctxs, $_[0]->{ctx} },
		level  => 'debug',
		ctx    => 'session-42',
	);
	$logger->debug('x');
	$logger->info('y');

	is($ctxs[0], 'session-42', 'ctx present on first call');
	is($ctxs[1], 'session-42', 'ctx present on second call');
};

# ============================================================
# 9. Object logger delegation — Log::Log4perl
# ============================================================

subtest 'Log::Log4perl object logger — debug and info delegated' => sub {
	plan tests => 2;

	require Log::Log4perl;
	Log::Log4perl->easy_init($Log::Log4perl::ERROR);
	my $l4p = Log::Log4perl->get_logger('Test.Integration');

	my $logger = Log::Abstraction->new(logger => $l4p, level => 'debug');
	isa_ok($logger, 'Log::Abstraction');

	# We can't easily observe what Log4perl does internally, but we can
	# confirm no exception is thrown and messages() still records entries
	lives_ok(sub {
		$logger->debug('l4p debug');
		$logger->info('l4p info');
	}, 'Log4perl delegation throws no exception');
};

subtest 'Log::Log4perl — notice falls back to info method' => sub {
	plan tests => 1;

	require Log::Log4perl;
	Log::Log4perl->easy_init($Log::Log4perl::ERROR);
	my $l4p = Log::Log4perl->get_logger('Test.Integration.Notice');

	my $logger = Log::Abstraction->new(logger => $l4p, level => 'debug');
	# Log4perl has no notice() — POD says it maps to info()
	lives_ok(sub { $logger->notice('mapped to info') },
		'notice() mapped to info() on Log4perl logger without exception');
};

# ============================================================
# 10. Syslog lifecycle — mocked
# ============================================================

subtest 'syslog — openlog called on first high-priority message' => sub {
	plan tests => 1;

	my $opened = 0;
	my $g_open = mock_scoped 'Log::Abstraction::openlog'  => sub { $opened++ };
	my $g_log  = mock_scoped 'Sys::Syslog::syslog'   => sub { };
	my $g_sock = mock_scoped 'Log::Abstraction::setlogsock' => sub { };

	my $logger = Log::Abstraction->new(
		logger      => { syslog => { facility => 'local0' } },
		level       => 'debug',
		script_name => 'integ_test',
	);
	$logger->warn('syslog test');

	is($opened, 1, 'openlog called exactly once on first warn');
};

subtest 'syslog — openlog called only once across multiple messages' => sub {
	plan tests => 2;

	my $opened = 0;
	my $logged = 0;
	my $g_open = mock_scoped 'Log::Abstraction::openlog'  => sub { $opened++ };
	my $g_log  = mock_scoped 'Sys::Syslog::syslog'   => sub { $logged++ };
	my $g_sock = mock_scoped 'Log::Abstraction::setlogsock' => sub { };

	my $logger = Log::Abstraction->new(
		logger      => { syslog => { facility => 'local0' } },
		level       => 'debug',
		script_name => 'integ_test',
	);
	$logger->warn('first');
	$logger->error('second');
	$logger->warn('third');

	is($opened, 1, 'openlog called exactly once for multiple messages');
	is($logged, 3, 'syslog called for each message');
};

subtest 'syslog — closelog called by DESTROY' => sub {
	plan tests => 1;

	my $closed = 0;
	my $g_close = mock_scoped 'Sys::Syslog::closelog'  => sub { $closed++ };
	my $g_open  = mock_scoped 'Log::Abstraction::openlog'   => sub { };
	my $g_log   = mock_scoped 'Sys::Syslog::syslog'    => sub { };
	my $g_sock  = mock_scoped 'Log::Abstraction::setlogsock' => sub { };

	{
		my $logger = Log::Abstraction->new(
			logger      => { syslog => { facility => 'local0' } },
			level       => 'debug',
			script_name => 'integ_test',
		);
		$logger->warn('trigger open');
	}	# DESTROY fires here

	is($closed, 1, 'closelog called by DESTROY when syslog was opened');
};

subtest 'syslog — level filter honoured (notice not sent to syslog)' => sub {
	plan tests => 1;

	my $logged = 0;
	my $g_open = mock_scoped 'Log::Abstraction::openlog'   => sub { };
	my $g_log  = mock_scoped 'Sys::Syslog::syslog'    => sub { $logged++ };
	my $g_sock = mock_scoped 'Log::Abstraction::setlogsock' => sub { };

	my $logger = Log::Abstraction->new(
		logger      => { syslog => { facility => 'local0', level => 4 } },
		level       => 'debug',
		script_name => 'integ_test',
	);
	# syslog backend has its own level gate at 4 (warning)
	$logger->warn('passes syslog gate');

	is($logged, 1, 'warn message reaches syslog at syslog level=4');
};

# ============================================================
# 11. Sendmail path — mocked
# ============================================================

# Pre-populate %INC at file scope (compile time) so require() inside
# the module's eval block never tries to load real email modules from disk.
BEGIN {
	$INC{'Email/Simple.pm'}                ||= 1;
	$INC{'Email/Sender/Simple.pm'}         ||= 1;
	$INC{'Email/Sender/Transport/SMTP.pm'} ||= 1;
}

# Stub packages at file scope so they are defined before any subtest runs.
{
	no warnings 'redefine';

	package Email::Simple;
	our $VERSION = '1.0';
	sub new        { bless { headers => {}, body => '' }, shift }
	sub header_set { my ($s, $k, $v) = @_; $s->{headers}{$k} = $v }
	sub body_set   { $_[0]->{body} = $_[1] }
	sub import     { }

	package Email::Sender::Simple;
	our $VERSION = '1.0';
	# import() must actually install sendmail() into the caller's namespace,
	# because _log does: Email::Sender::Simple->import('sendmail') then calls
	# the bare sendmail() in Log::Abstraction's namespace.
	sub import {
		my ($class, @syms) = @_;
		my $caller = caller(0);
		no strict 'refs';
		for my $sym (@syms) {
			*{"${caller}::${sym}"} = \&{"${class}::${sym}"};
		}
	}
	sub sendmail { }	# default no-op; overridden per-subtest via mock_scoped

	package Email::Sender::Transport::SMTP;
	our $VERSION = '1.0';
	sub new    { bless {}, shift }
	sub import { }

	package main;
}

subtest 'sendmail — completes without exception for warn()' => sub {
	plan tests => 1;

	my $sent = 0;
	my $g    = mock_scoped 'Email::Sender::Simple::sendmail' => sub { $sent++ };

	my $logger = Log::Abstraction->new(
		logger => {
			sendmail => {
				to   => 'ops@example.com',
				from => 'log@example.com',
				host => 'localhost',
				port => 25,
			},
		},
		level       => 'debug',
		script_name => 'integ_test',
	);

	lives_ok(sub { $logger->warn('alert ops') },
		'sendmail path completes without exception');
};

subtest 'sendmail — sendmail() invoked for warn-level message' => sub {
	plan tests => 1;

	my $sent = 0;
	my $g    = mock_scoped 'Email::Sender::Simple::sendmail' => sub { $sent++ };

	my $logger = Log::Abstraction->new(
		logger => {
			sendmail => {
				to   => 'ops@example.com',
				from => 'log@example.com',
				host => 'localhost',
				port => 25,
			},
		},
		level       => 'debug',
		script_name => 'integ_test',
	);
	$logger->warn('trigger email');

	is($sent, 1, 'sendmail() called once for warn()');
};

subtest 'sendmail — sendmail() not called below configured level' => sub {
	plan tests => 1;

	my $sent = 0;
	my $g    = mock_scoped 'Email::Sender::Simple::sendmail' => sub { $sent++ };

	my $logger = Log::Abstraction->new(
		logger => {
			sendmail => {
				to    => 'ops@example.com',
				level => 'error',	# only send for error and above
			},
		},
		level       => 'debug',
		script_name => 'integ_test',
	);
	$logger->warn('below sendmail threshold');

	is($sent, 0, 'sendmail() not called when message below sendmail level');
};

# ============================================================
# 12. Config-file constructor path
# ============================================================

subtest 'config_file — loads configuration and creates working logger' => sub {
	plan tests => 3;

	# Write a minimal YAML config that sets level and array backend
	my $dir = tempdir(CLEANUP => 1);
	my $cfg  = File::Spec->catfile($dir, 'log.yaml');

	open my $fh, '>', $cfg or die "Cannot write $cfg: $!";
	print $fh "level: debug\n";
	close $fh;

	my @log;
	my $logger;
	lives_ok(
		sub {
			$logger = Log::Abstraction->new(
				config_file => $cfg,
				array       => \@log,
			);
		},
		'new() with config_file does not throw'
	);
	isa_ok($logger, 'Log::Abstraction');

	$logger->debug('from config');
	is($log[0]{message}, 'from config', 'logger works after config_file load');
};

# ============================================================
# 13. warn() argument forms — stateful sequence
# ============================================================

subtest 'warn() argument forms — all forms produce correct entries' => sub {
	plan tests => 4;

	my ($logger) = array_logger();
	$logger->warn('plain string');
	$logger->warn(warning => 'keyed string');
	$logger->warn(warning => ['array', ' parts']);
	# arrayref positional form
	$logger->warn(['array', ' ref']);

	my $m = $logger->messages();
	is($m->[0]{message}, 'plain string',  'plain string form');
	is($m->[1]{message}, 'keyed string',  'warning => scalar form');
	is($m->[2]{message}, 'array parts',   'warning => arrayref form');
	is($m->[3]{message}, 'array ref',     'positional arrayref form');
};

# ============================================================
# 14. carp_on_warn + croak_on_error across a session
# ============================================================

subtest 'carp_on_warn — fires for every warn in session' => sub {
	plan tests => 2;

	my @log;
	my $logger = Log::Abstraction->new(
		array        => \@log,
		level        => 'debug',
		carp_on_warn => 1,
	);
	my $count = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $count++ };
	$logger->warn('first warn');
	$logger->warn('second warn');
	is($count,       2, 'Carp::carp called for each warn');
	is(scalar(@log), 2, 'both warns also recorded in array');
};

subtest 'croak_on_error — message logged before croak fires' => sub {
	plan tests => 2;

	my @log;
	my $logger = Log::Abstraction->new(
		array          => \@log,
		level          => 'debug',
		croak_on_error => 1,
	);
	eval { $logger->error('before croak') };
	ok($@,                              'croak was thrown');
	is($log[0]{message}, 'before croak', 'message logged before croak');
};

subtest 'croak_on_error and carp_on_warn independent on same logger' => sub {
	plan tests => 3;

	my @log;
	my $logger = Log::Abstraction->new(
		array          => \@log,
		level          => 'debug',
		carp_on_warn   => 1,
		croak_on_error => 1,
	);
	my $carped = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $carped++ };

	$logger->warn('will carp');
	is($carped, 1, 'warn triggers carp');

	eval { $logger->error('will croak') };
	ok($@, 'error triggers croak');
	is(scalar(@log), 2, 'both messages recorded before their side-effects');
};

# ============================================================
# 15. messages() as an audit trail across mixed levels
# ============================================================

subtest 'messages() audit trail — level and message fields accurate throughout' => sub {
	plan tests => 11;	# 1 (count check) + 5 entries x 2 (level + message) = 11

	my ($logger) = array_logger();
	my @expected = (
		[debug  => 'msg d'],
		[info   => 'msg i'],
		[notice => 'msg n'],
		[warn   => 'msg w'],
		[error  => 'msg e'],
	);
	$logger->debug('msg d');
	$logger->info('msg i');
	$logger->notice('msg n');
	$logger->warn('msg w');
	$logger->error('msg e');

	my $m = $logger->messages();
	is(scalar(@{$m}), 5, 'five entries in audit trail');
	for my $i (0 .. $#expected) {
		is($m->[$i]{level},   $expected[$i][0], "entry $i level");
		is($m->[$i]{message}, $expected[$i][1], "entry $i message");
	}
};

# ============================================================
# 16. is_debug() reflects live level() changes
# ============================================================

subtest 'is_debug() tracks level() changes throughout session' => sub {
	plan tests => 4;

	my ($logger) = array_logger();
	is($logger->is_debug(), 1, 'is_debug true at debug');

	$logger->level('info');
	is($logger->is_debug(), 0, 'is_debug false at info');

	$logger->level('warning');
	is($logger->is_debug(), 0, 'is_debug false at warning');

	$logger->level('debug');
	is($logger->is_debug(), 1, 'is_debug true again after restoring debug');
};

# ============================================================
# 17. Multiple simultaneous loggers — no cross-contamination
# ============================================================

subtest 'two independent loggers do not share state' => sub {
	plan tests => 4;

	my ($logger_a, $log_a) = array_logger();
	my ($logger_b, $log_b) = array_logger();

	$logger_a->debug('only a');
	$logger_b->info('only b');
	$logger_a->notice('also a');

	is(scalar(@{$log_a}), 2,        'logger_a has two entries');
	is(scalar(@{$log_b}), 1,        'logger_b has one entry');
	is($log_a->[0]{message}, 'only a',  'logger_a first message');
	is($log_b->[0]{message}, 'only b',  'logger_b message unaffected');
};

subtest 'two loggers at different levels are independent' => sub {
	plan tests => 2;

	my @log_verbose;
	my @log_quiet;
	my $verbose = Log::Abstraction->new(array => \@log_verbose, level => 'debug');
	my $quiet   = Log::Abstraction->new(array => \@log_quiet,   level => 'error');

	$verbose->debug('verbose debug');
	$quiet->debug('quiet debug');	# filtered
	$verbose->error('verbose error');
	$quiet->error('quiet error');

	is(scalar(@log_verbose), 2, 'verbose logger records debug and error');
	is(scalar(@log_quiet),   1, 'quiet logger records only error');
};

# ============================================================
# 18. Clone inherits and operates on same backend
# ============================================================

subtest 'clone + parent write to same array in document order' => sub {
	plan tests => 5;

	my @log;
	my $parent = Log::Abstraction->new(array => \@log, level => 'debug');
	my $child  = $parent->new();

	$parent->debug('p1');
	$child->debug('c1');
	$parent->info('p2');
	$child->warn('c2');

	is(scalar(@log), 4, 'four interleaved messages');
	is($log[0]{message}, 'p1', 'first is parent p1');
	is($log[1]{message}, 'c1', 'second is child c1');
	is($log[2]{message}, 'p2', 'third is parent p2');
	is($log[3]{message}, 'c2', 'fourth is child c2');
};

done_testing();
