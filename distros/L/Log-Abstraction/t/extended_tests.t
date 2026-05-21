#!/usr/bin/env perl

# extended_tests.t - Coverage-driven tests targeting branches, conditions and
# paths not exercised by function.t, unit.t, integration.t or edge_cases.t.
#
# Goals:
#   * Drive statement/branch coverage above 95%
#   * Improve LCSAJ/TER3 by covering every distinct linearly-independent path
#     through each method, including compound boolean conditions
#
# Organisation follows the module source top-to-bottom so coverage gaps are
# easy to map back to source lines.

use strict;
use warnings;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Log::Abstraction;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Mockingbird qw(mock_scoped);

# ---------------------------------------------------------------------------
# Email module stubs — must be in %INC before Log::Abstraction's _log
# tries to require them.
# ---------------------------------------------------------------------------
BEGIN {
	$INC{'Email/Simple.pm'}                ||= 1;
	$INC{'Email/Sender/Simple.pm'}         ||= 1;
	$INC{'Email/Sender/Transport/SMTP.pm'} ||= 1;
}
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
	sub import {
		my ($class, @syms) = @_;
		my $caller = caller(0);
		no strict 'refs';
		for my $sym (@syms) {
			*{"${caller}::${sym}"} = \&{"${class}::${sym}"};
		}
	}
	sub sendmail { }

	package Email::Sender::Transport::SMTP;
	our $VERSION = '1.0';
	sub new    { bless {}, shift }
	sub import { }

	package main;
}

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
# 1. new() — config_file path
# ============================================================

subtest 'new() — config_file not readable croaks' => sub {
	plan tests => 1;

	throws_ok(
		sub {
			Log::Abstraction->new(
				config_file => '/nonexistent/path/to/config.yaml',
				array       => [],
			)
		},
		qr/File not readable/i,
		'unreadable config_file causes croak'
	);
};

subtest 'new() — config_file with level key configures logger' => sub {
	plan tests => 2;

	my $dir = tempdir(CLEANUP => 1);
	my $cfg = File::Spec->catfile($dir, 'test.yaml');
	open my $fh, '>', $cfg or die $!;
	print $fh "level: info\n";
	close $fh;

	my @log;
	my $logger = Log::Abstraction->new(config_file => $cfg, array => \@log);
	isa_ok($logger, 'Log::Abstraction');

	# info passes at info level, debug filtered
	$logger->debug('filtered');
	$logger->info('passes');
	is(scalar(@log), 1, 'config_file level=info filters debug correctly');
};

subtest 'new() — config_file: explicit array arg preserved over config' => sub {
	plan tests => 2;

	# Even if the config file sets its own keys, the explicit array => \@log
	# passed to new() must survive the config merge.
	my $dir = tempdir(CLEANUP => 1);
	my $cfg = File::Spec->catfile($dir, 'test.yaml');
	open my $fh, '>', $cfg or die $!;
	print $fh "level: debug\n";
	close $fh;

	my @log;
	my $logger = Log::Abstraction->new(config_file => $cfg, array => \@log);
	$logger->debug('via config');
	is(scalar(@log), 1,             'array backend active after config_file load');
	is($log[0]{message}, 'via config', 'message correct');
};

# ============================================================
# 2. new() — verbose flag → Log4perl DEBUG
# ============================================================

# Pre-require Log::Log4perl so the mock is applied AFTER the module is fully
# loaded — otherwise Log4perl's own require wipes out the mock during loading.
BEGIN { require Log::Log4perl; Log::Log4perl->import() }

subtest 'new() — verbose=>1 calls easy_init with DEBUG level' => sub {
	plan tests => 1;

	my $init_arg;
	# easy_init is called as Log::Log4perl->easy_init($level), an OO call,
	# so mock at Log::Log4perl::easy_init; $_[0]=class, $_[1]=level arg.
	my $g = mock_scoped 'Log::Log4perl::easy_init' => sub { $init_arg = $_[1] };

	Log::Abstraction->new(verbose => 1);
	is($init_arg, $Log::Log4perl::DEBUG, 'verbose=>1 passes DEBUG to easy_init');
};

subtest 'new() — without verbose calls easy_init with ERROR level' => sub {
	plan tests => 1;

	my $init_arg;
	my $g = mock_scoped 'Log::Log4perl::easy_init' => sub { $init_arg = $_[1] };

	Log::Abstraction->new();
	is($init_arg, $Log::Log4perl::ERROR, 'no verbose passes ERROR to easy_init');
};

# ============================================================
# 3. new() — syslog + SCRIPT_NAME env var
# ============================================================

subtest 'new() — syslog uses SCRIPT_NAME env var when set' => sub {
	plan tests => 1;

	local $ENV{SCRIPT_NAME} = 'my_web_script';

	# array => \@sink prevents the Log4perl default-logger path from firing
	my @sink;
	my $logger = Log::Abstraction->new(
		syslog => { facility => 'local0' },
		level  => 'debug',
		array  => \@sink,
	);
	is($logger->{script_name}, 'my_web_script', 'script_name taken from SCRIPT_NAME env var');
};

subtest 'new() — syslog falls back to $0 when SCRIPT_NAME not set' => sub {
	plan tests => 1;

	local $ENV{SCRIPT_NAME} = undef;
	delete $ENV{SCRIPT_NAME};

	my @sink;
	my $logger = Log::Abstraction->new(
		syslog => { facility => 'local0' },
		level  => 'debug',
		array  => \@sink,
	);
	require File::Basename;
	my $expected = File::Basename::basename($0);
	is($logger->{script_name}, $expected, 'script_name falls back to basename($0)');
};

# ============================================================
# 4. _log() — hash-ref logger, file open failure
# ============================================================

subtest '_log() — hash-ref logger: silent no-op when file cannot be opened' => sub {
	plan tests => 2;

	# Point at a directory (not a file) — open for append will fail
	my $dir = tempdir(CLEANUP => 1);
	my $logger = Log::Abstraction->new(
		logger => { file => $dir },
		level  => 'debug',
	);
	# Should not croak — the open failure path is a silent skip
	lives_ok(sub { $logger->debug('open fail test') }, 'no croak on file open failure');
	# Internal messages store should still be populated
	is(scalar(@{$logger->messages()}), 1, 'internal messages() populated despite open failure');
};

# ============================================================
# 5. _log() — hash-ref logger: none of file/syslog/sendmail → croak
# ============================================================

subtest '_log() — hash-ref logger with no actionable key croaks' => sub {
	plan tests => 1;

	# The croak guard fires when none of file/array/syslog/sendmail/fd
	# produce output. Guard uses !exists($logger->{'sendmail'}) to avoid
	# autovivification from the earlier exists($logger->{'sendmail'})&&exists(to) check.
	my $logger = Log::Abstraction->new(
		logger => { unrecognised_key => 1 },
		level  => 'debug',
	);
	throws_ok(
		sub { $logger->debug('trigger') },
		qr/Don.t know how to deal/i,
		'hash-ref logger with no valid key croaks'
	);
};

# ============================================================
# 6. _log() — sendmail branches
# ============================================================

subtest 'sendmail — from not set defaults to noreply@localhost' => sub {
	plan tests => 1;

	my @headers;
	{
		no warnings 'redefine';
		*Email::Simple::header_set = sub {
			my ($self, $key, $val) = @_;
			push @headers, [$key, $val];
		};
	}
	my $g = mock_scoped 'Email::Sender::Simple::sendmail' => sub { };

	my $logger = Log::Abstraction->new(
		logger => {
			sendmail => {
				to   => 'dest@example.com',
				# deliberately no 'from'
				host => 'localhost',
			},
		},
		level       => 'debug',
		script_name => 'ext_test',
	);
	$logger->warn('no from test');

	my ($from_header) = grep { $_->[0] eq 'from' } @headers;
	is($from_header->[1], 'noreply@localhost', 'from defaults to noreply@localhost');
};

subtest 'sendmail — subject header set when configured' => sub {
	plan tests => 1;

	my @headers;
	{
		no warnings 'redefine';
		*Email::Simple::header_set = sub {
			my ($self, $key, $val) = @_;
			push @headers, [$key, $val];
		};
	}
	my $g = mock_scoped 'Email::Sender::Simple::sendmail' => sub { };

	my $logger = Log::Abstraction->new(
		logger => {
			sendmail => {
				to      => 'dest@example.com',
				subject => 'Alert: log event',
				host    => 'localhost',
			},
		},
		level       => 'debug',
		script_name => 'ext_test',
	);
	$logger->warn('subject test');

	my ($subj) = grep { $_->[0] eq 'subject' } @headers;
	is($subj->[1], 'Alert: log event', 'subject header set from config');
};

subtest 'sendmail — not called when level above sendmail threshold' => sub {
	plan tests => 1;

	my $sent = 0;
	my $g    = mock_scoped 'Email::Sender::Simple::sendmail' => sub { $sent++ };

	my $logger = Log::Abstraction->new(
		logger => {
			sendmail => {
				to    => 'dest@example.com',
				level => 'error',	# only send at error (3) or above
			},
		},
		level       => 'debug',
		script_name => 'ext_test',
	);
	$logger->warn('below email threshold');	# warn=4, error=3: 4 > 3 so skip
	is($sent, 0, 'sendmail not invoked when warn level above sendmail threshold');
};

subtest 'sendmail — called when level at or below sendmail threshold' => sub {
	plan tests => 1;

	my $sent = 0;
	my $g    = mock_scoped 'Email::Sender::Simple::sendmail' => sub { $sent++ };

	my $logger = Log::Abstraction->new(
		logger => {
			sendmail => {
				to    => 'dest@example.com',
				level => 'warn',	# send at warn (4) or above (more severe)
				host  => 'localhost',
			},
		},
		level       => 'debug',
		script_name => 'ext_test',
	);
	$logger->warn('at threshold');
	is($sent, 1, 'sendmail invoked when level equals sendmail threshold');
};

subtest 'sendmail — no level key means always send' => sub {
	plan tests => 1;

	my $sent = 0;
	my $g    = mock_scoped 'Email::Sender::Simple::sendmail' => sub { $sent++ };

	my $logger = Log::Abstraction->new(
		logger => {
			sendmail => {
				to   => 'dest@example.com',
				host => 'localhost',
			},
		},
		level       => 'debug',
		script_name => 'ext_test',
	);
	$logger->warn('always send');
	is($sent, 1, 'sendmail always called when no level key');
};

subtest 'sendmail — failure carps and returns without croak' => sub {
	plan tests => 2;

	my $carped = 0;
	# Make sendmail die inside the eval
	my $g_send  = mock_scoped 'Email::Sender::Simple::sendmail' => sub { die "SMTP refused\n" };
	my $g_carp  = mock_scoped 'Carp::carp' => sub { $carped++ };

	my ($logger, $log) = array_logger();
	# Reconfigure with sendmail backend alongside array
	$logger = Log::Abstraction->new(
		logger => {
			sendmail => { to => 'x@example.com', host => 'localhost' },
		},
		level       => 'debug',
		script_name => 'ext_test',
	);

	lives_ok(sub { $logger->warn('fail send') }, 'sendmail failure does not propagate exception');
	is($carped, 1, 'sendmail failure triggers Carp::carp');
};

# ============================================================
# 7. _log() — syslog branches
# ============================================================

subtest 'syslog — error level maps to priority "err" not "warning"' => sub {
	plan tests => 1;

	my $logged_priority;
	my $g_open = mock_scoped 'Log::Abstraction::openlog'  => sub { };
	my $g_log  = mock_scoped 'Sys::Syslog::syslog'        => sub { $logged_priority = $_[0] };
	my $g_sock = mock_scoped 'Log::Abstraction::setlogsock' => sub { };

	my $logger = Log::Abstraction->new(
		logger      => { syslog => { facility => 'local0' } },
		level       => 'debug',
		script_name => 'ext_test',
	);
	$logger->error('err priority test');
	like($logged_priority, qr/^err\|/, 'error level uses syslog priority "err"');
};

subtest 'syslog — warn level maps to priority "warning"' => sub {
	plan tests => 1;

	my $logged_priority;
	my $g_open = mock_scoped 'Log::Abstraction::openlog'   => sub { };
	my $g_log  = mock_scoped 'Sys::Syslog::syslog'         => sub { $logged_priority = $_[0] };
	my $g_sock = mock_scoped 'Log::Abstraction::setlogsock' => sub { };

	my $logger = Log::Abstraction->new(
		logger      => { syslog => { facility => 'local0' } },
		level       => 'debug',
		script_name => 'ext_test',
	);
	$logger->warn('warning priority test');
	like($logged_priority, qr/^warning\|/, 'warn level uses syslog priority "warning"');
};

subtest 'syslog — server key renamed to host before setlogsock' => sub {
	plan tests => 1;

	my %sock_args;
	my $g_open = mock_scoped 'Log::Abstraction::openlog'   => sub { };
	my $g_log  = mock_scoped 'Sys::Syslog::syslog'         => sub { };
	my $g_sock = mock_scoped 'Sys::Syslog::setlogsock' => sub { %sock_args = %{$_[0]} };

	my $logger = Log::Abstraction->new(
		logger      => { syslog => { facility => 'local0', server => '10.0.0.1' } },
		level       => 'debug',
		script_name => 'ext_test',
	);
	$logger->warn('server rename test');
	ok(exists $sock_args{host}, 'server key renamed to host for setlogsock');
};

subtest 'syslog — setlogsock not called when syslog hash is empty after key extraction' => sub {
	plan tests => 1;

	my $sock_called = 0;
	my $g_open = mock_scoped 'Log::Abstraction::openlog'   => sub { };
	my $g_log  = mock_scoped 'Sys::Syslog::syslog'         => sub { };
	my $g_sock = mock_scoped 'Log::Abstraction::setlogsock' => sub { $sock_called++ };

	# Only facility and level — both deleted before the setlogsock check
	# leaving an empty hash → setlogsock not called
	my $logger = Log::Abstraction->new(
		logger      => { syslog => { facility => 'local0' } },
		level       => 'debug',
		script_name => 'ext_test',
	);
	$logger->warn('empty syslog hash');
	is($sock_called, 0, 'setlogsock not called when no extra syslog keys');
};

subtest 'syslog — syslog() failure carps with Data::Dumper output' => sub {
	plan tests => 1;

	my $carped = 0;
	my $g_open = mock_scoped 'Log::Abstraction::openlog' => sub { };
	my $g_log  = mock_scoped 'Sys::Syslog::syslog'       => sub { die "syslog failed\n" };
	my $g_sock = mock_scoped 'Log::Abstraction::setlogsock' => sub { };
	my $g_carp = mock_scoped 'Carp::carp'                => sub { $carped++ };

	my $logger = Log::Abstraction->new(
		logger      => { syslog => { facility => 'local0' } },
		level       => 'debug',
		script_name => 'ext_test',
	);
	$logger->warn('syslog die test');
	is($carped, 1, 'syslog() failure triggers Carp::carp');
};

subtest 'syslog — message skipped when below syslog level threshold' => sub {
	plan tests => 1;

	my $logged = 0;
	my $g_open = mock_scoped 'Log::Abstraction::openlog' => sub { };
	my $g_log  = mock_scoped 'Sys::Syslog::syslog'       => sub { $logged++ };
	my $g_sock = mock_scoped 'Log::Abstraction::setlogsock' => sub { };

	# syslog level set to 3 (error); warn(4) > 3 so syslog skipped
	my $logger = Log::Abstraction->new(
		logger      => { syslog => { facility => 'local0', level => 3 } },
		level       => 'debug',
		script_name => 'ext_test',
	);
	$logger->warn('below syslog threshold');
	is($logged, 0, 'syslog() not called when message above (less severe than) syslog level');
};

# ============================================================
# 8. _log() — format %class% with subclass
# ============================================================

subtest '_log() — %class% token populated for subclassed logger' => sub {
	plan tests => 1;

	# Create a subclass so blessed($self) ne __PACKAGE__
	{ package My::Logger; our @ISA = ('Log::Abstraction'); }

	my $path = tmp_file();
	my @sink;
	my $logger = bless Log::Abstraction->new(
		file   => $path,
		array  => \@sink,
		level  => 'debug',
		format => '%class%',
	), 'My::Logger';

	$logger->debug('class token test');
	my $content = slurp($path);
	like($content, qr/My::Logger/, '%class% expands to subclass name');
};

subtest '_log() — %class% empty when blessed as Log::Abstraction itself' => sub {
	plan tests => 1;

	my $path = tmp_file();
	my @sink;
	my $logger = Log::Abstraction->new(
		file   => $path,
		array  => \@sink,
		level  => 'debug',
		format => '[%class%]',
	);
	$logger->debug('base class token test');
	my $content = slurp($path);
	# class is set to '' for the base package, so token expands to empty
	like($content, qr/\[\]/, '%class% expands to empty string for base package');
};

# ============================================================
# 9. _log() — top-level file: base package uses shorter format
# ============================================================

subtest '_log() — top-level file: base class omits %class% from default format' => sub {
	plan tests => 1;

	my $path = tmp_file();
	# No format specified — uses default; base class default omits %class%
	my $logger = Log::Abstraction->new(file => $path, level => 'debug');
	$logger->debug('base format test');
	my $content = slurp($path);
	like($content, qr/DEBUG/i, 'default format writes level to file');
};

# ============================================================
# 10. _log() — string (file path) logger open failure
# ============================================================

subtest '_log() — string logger: silent no-op when file cannot be opened' => sub {
	plan tests => 2;

	# Use a directory path — open for append will fail
	my $dir = tempdir(CLEANUP => 1);
	my $logger = Log::Abstraction->new(logger => $dir, level => 'debug');
	lives_ok(sub { $logger->debug('open fail') }, 'string logger open failure does not croak');
	is(scalar(@{$logger->messages()}), 1, 'message still in internal store');
};

# ============================================================
# 11. _log() — hash-ref logger: fd key
# ============================================================

subtest '_log() — hash-ref logger fd key writes to filehandle' => sub {
	plan tests => 2;

	my ($fh, $path) = tempfile(SUFFIX => '.log', UNLINK => 1);
	my $logger = Log::Abstraction->new(
		logger => { fd => $fh },
		level  => 'debug',
	);
	$logger->debug('hash fd test');
	close $fh;

	my $content = slurp($path);
	like($content, qr/hash fd test/, 'message written via hash-ref fd logger');
	like($content, qr/DEBUG/i,       'level present in hash-ref fd output');
};

subtest '_log() — hash-ref logger fd: format tokens expanded' => sub {
	plan tests => 2;

	local $ENV{EXT_TEST_VAR} = 'extended_val';
	my ($fh, $path) = tempfile(SUFFIX => '.log', UNLINK => 1);
	my $logger = Log::Abstraction->new(
		logger => { fd => $fh },
		level  => 'debug',
		format => '%level%|%env_EXT_TEST_VAR%',
	);
	$logger->info('fd format test');
	close $fh;

	my $content = slurp($path);
	like($content, qr/INFO/i,          '%level% expanded in hash-ref fd format');
	like($content, qr/extended_val/,   '%env_*% expanded in hash-ref fd format');
};

# ============================================================
# 12. _high_priority — plain list (multiple args) correctly joined
# ============================================================

subtest '_high_priority — plain multi-arg list joined correctly' => sub {
	plan tests => 2;

	# CODE FIX NEEDED: Params::Get throws "Usage:" on odd-count plain lists
	# (e.g. 3 args) that don't start with a recognised key name.
	# _high_priority must wrap get_params in eval{} and fall back to
	# join(grep{defined}@_) when get_params fails or returns no 'warning' key.
	my ($logger, $log) = array_logger();
	local $TODO = 'odd-count plain list: _high_priority must eval{} get_params call';
	$logger->warn('alpha ', 'beta ', 'gamma');
	is(scalar(@{$log}), 1,                    'one entry for multi-arg warn');
	is($log->[0]{message}, 'alpha beta gamma', 'multi-arg warn joined correctly');
};

subtest '_high_priority — plain list with one arg' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn('single');
	is($log->[0]{message}, 'single', 'single-arg warn stored correctly');
};

subtest '_high_priority — error() with plain multi-arg list' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	local $TODO = 'odd-count plain list: _high_priority must eval{} get_params call';
	$logger->error('err ', 'part1 ', 'part2');
	is(scalar(@{$log}), 1,                    'one entry for multi-arg error');
	is($log->[0]{message}, 'err part1 part2', 'multi-arg error joined correctly');
};

subtest '_high_priority — warning => arrayref with mixed defined/undef' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn(warning => ['good ', undef, 'also good']);
	is($log->[0]{message}, 'good also good', 'undef entries filtered from warning arrayref');
};

subtest '_high_priority — fatal() with plain list' => sub {
	plan tests => 2;

	my ($logger, $log) = array_logger();
	$logger->fatal('fatal ', 'event');
	is(scalar(@{$log}), 1,               'one entry for multi-arg fatal');
	is($log->[0]{message}, 'fatal event', 'fatal multi-arg joined correctly');
};

# ============================================================
# 13. _high_priority — $self eq __PACKAGE__ class-method path
# ============================================================

subtest '_high_priority — warn called as class method croaks via carp' => sub {
	plan tests => 1;

	# When $self eq __PACKAGE__ (string comparison), the method uses
	# Carp::carp (for warn) or Carp::croak (for error) and returns.
	my $carped = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $carped++ };

	# Force the class-method path: pass the package name as self
	Log::Abstraction->_high_priority('warn', warning => 'class method warn');
	# NB: $self will be 'Log::Abstraction' (a string), so $self eq __PACKAGE__ is true
	is($carped, 1, 'class-method warn path triggers Carp::carp');
};

subtest '_high_priority — error called as class method croaks' => sub {
	plan tests => 1;

	throws_ok(
		sub { Log::Abstraction->_high_priority('error', warning => 'class method error') },
		qr/class method error/,
		'class-method error path triggers Carp::croak with message'
	);
};

# ============================================================
# 14. level() — edge cases
# ============================================================

subtest 'level() — called with 0 (falsy) acts as getter not setter' => sub {
	plan tests => 2;

	my ($logger) = array_logger();	# level=debug=7
	my $before = $logger->level();
	my $result = $logger->level(0);	# 0 is falsy → if($level) is false → getter path
	is($result,         $before, 'level(0) returns current level (getter path)');
	is($logger->level(), $before, 'level unchanged after level(0)');
};

subtest 'level() — return value matches stored integer' => sub {
	plan tests => 4;

	my ($logger) = array_logger();
	for my $pair (['info', 6], ['notice', 5], ['warn', 4], ['error', 3]) {
		$logger->level($pair->[0]);
		is($logger->level(), $pair->[1], "level('$pair->[0]') → $pair->[1]");
	}
};

# ============================================================
# 15. is_debug() — full boolean coverage
# ============================================================

subtest 'is_debug() — level=0 (emerg) returns false' => sub {
	plan tests => 1;

	my ($logger) = array_logger();
	# Force level to 0 directly (emerg — most severe, never set normally)
	$logger->{level} = 0;
	is($logger->is_debug(), 0, 'is_debug false when level=0 (emerg)');
};

subtest 'is_debug() — level=7 (debug) returns true' => sub {
	plan tests => 1;

	my ($logger) = array_logger('debug');
	is($logger->is_debug(), 1, 'is_debug true at level 7');
};

subtest 'is_debug() — level=6 (info) returns false' => sub {
	plan tests => 1;

	my ($logger) = array_logger('info');
	is($logger->is_debug(), 0, 'is_debug false at level 6 (info)');
};

# ============================================================
# 16. warn() — all documented call forms
# ============================================================

subtest 'warn() — positional arrayref \@messages form' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	my @msgs = ('ref ', 'message');
	$logger->warn(\@msgs);
	is($log->[0]{message}, 'ref message', 'positional arrayref joined correctly');
};

subtest 'warn() — hashref argument form' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn({ warning => 'hashref form' });
	is($log->[0]{message}, 'hashref form', 'hashref warning form works');
};

subtest 'warn() — empty list is no-op (pre-guard in warn())' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn();
	is(scalar(@{$log}), 0, 'warn() with no args logs nothing');
};

subtest 'warn() — all-defined list produces correct concatenation' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->warn('a', 'b', 'c');
	is($log->[0]{message}, 'abc', 'all-defined list concatenated');
};

# ============================================================
# 17. error() and fatal() — all call forms
# ============================================================

subtest 'error() — warning => scalar form' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->error(warning => 'keyed error');
	is($log->[0]{message}, 'keyed error', 'error(warning=>scalar) works');
};

subtest 'error() — warning => arrayref form' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->error(warning => ['err ', 'parts']);
	is($log->[0]{message}, 'err parts', 'error(warning=>arrayref) joined');
};

subtest 'fatal() — warning => scalar form' => sub {
	plan tests => 1;

	my ($logger, $log) = array_logger();
	$logger->fatal(warning => 'keyed fatal');
	is($log->[0]{message}, 'keyed fatal', 'fatal(warning=>scalar) works');
};

# ============================================================
# 18. ctx in coderef logger — not forwarded when absent
# ============================================================

subtest 'coderef logger — ctx key absent when not configured' => sub {
	plan tests => 1;

	my %got;
	my $logger = Log::Abstraction->new(
		logger => sub { %got = %{$_[0]} },
		level  => 'debug',
	);
	$logger->debug('no ctx');
	ok(!exists $got{ctx}, 'ctx key absent from coderef args when not set in new()');
};

# ============================================================
# 19. Compound boolean paths in _high_priority fallback
# ============================================================

subtest 'carp_on_warn=0, no array, no logger → carp fires (no backend)' => sub {
	plan tests => 1;

	# When there is no logger AND no array, carp fires even without carp_on_warn
	my $carped = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $carped++ };

	# File-only logger: after _log writes to file, _high_priority checks
	# !defined($self->{logger}) && !defined($self->{array}) — both true
	my $path = tmp_file();
	my $logger = Log::Abstraction->new(file => $path, level => 'debug');
	$logger->warn('no backend warn');
	is($carped, 1, 'carp fires when no logger and no array backend');
};

subtest 'croak fires when no logger and no array for error()' => sub {
	plan tests => 1;

	my $path = tmp_file();
	my $logger = Log::Abstraction->new(file => $path, level => 'debug');
	throws_ok(
		sub { $logger->error('no backend error') },
		qr/no backend error/,
		'croak fires for error() when no logger and no array backend'
	);
};

subtest 'croak_on_error=1 with logger set still croaks' => sub {
	plan tests => 2;

	my @log;
	my $logger = Log::Abstraction->new(
		logger         => \@log,
		level          => 'debug',
		croak_on_error => 1,
	);
	throws_ok(
		sub { $logger->error('forced croak') },
		qr/forced croak/,
		'croak_on_error=1 croaks even with logger set'
	);
	is($log[0]{message}, 'forced croak', 'message logged before croak');
};

subtest 'carp_on_warn=1 with logger set still carps' => sub {
	plan tests => 2;

	my @log;
	my $carped = 0;
	my $g = mock_scoped 'Carp::carp' => sub { $carped++ };
	my $logger = Log::Abstraction->new(
		logger       => \@log,
		level        => 'debug',
		carp_on_warn => 1,
	);
	$logger->warn('forced carp');
	is($carped, 1,              'carp_on_warn=1 carps even with logger set');
	is($log[0]{message}, 'forced carp', 'message logged before carp');
};

# ============================================================
# 20. messages() — level field accuracy for all levels
# ============================================================

subtest 'messages() — level field set correctly for all six methods' => sub {
	plan tests => 6;

	my ($logger) = array_logger();
	$logger->debug('d');
	$logger->info('i');
	$logger->notice('n');
	$logger->warn('w');
	$logger->error('e');
	$logger->trace('t');

	my $m = $logger->messages();
	my %by_msg = map { $_->{message} => $_->{level} } @{$m};
	is($by_msg{d}, 'debug',  'debug level field');
	is($by_msg{i}, 'info',   'info level field');
	is($by_msg{n}, 'notice', 'notice level field');
	is($by_msg{w}, 'warn',   'warn level field');
	is($by_msg{e}, 'error',  'error level field');
	is($by_msg{t}, 'trace',  'trace level field');
};

# ============================================================
# 21. _sanitize_email_header — Return::Set schema compliance
# ============================================================

subtest '_sanitize_email_header — return value matches string regex schema' => sub {
	plan tests => 2;

	my $clean = Log::Abstraction::_sanitize_email_header('user@host.com');
	ok(defined $clean, 'defined value returned');
	unlike($clean, qr/[\r\n]/, 'return value contains no CR or LF');
};

subtest '_sanitize_email_header — multiple consecutive CR/LF sequences all stripped' => sub {
	plan tests => 1;

	my $result = Log::Abstraction::_sanitize_email_header("a\r\n\r\n\r\nb");
	is($result, 'ab', 'multiple CRLF sequences all stripped');
};

# ============================================================
# 22. clone — ctx inherited
# ============================================================

subtest 'clone — ctx inherited from parent' => sub {
	plan tests => 2;

	my %got;
	my $parent = Log::Abstraction->new(
		logger => sub { %got = %{$_[0]} },
		level  => 'debug',
		ctx    => 'parent-ctx',
	);
	my $child = $parent->new();
	$child->debug('ctx inherit test');
	is($got{ctx}, 'parent-ctx', 'child inherits ctx from parent');

	my $child2 = $parent->new(ctx => 'child-ctx');
	$child2->debug('ctx override test');
	is($got{ctx}, 'child-ctx', 'child can override ctx');
};

# ============================================================
# 23. Subclass: verify isa and delegation still work
# ============================================================

subtest 'subclass — inherits all Log::Abstraction methods' => sub {
	plan tests => 4;

	package My::AppLogger;
	our @ISA = ('Log::Abstraction');
	sub new {
		my ($class, %args) = @_;
		return $class->SUPER::new(%args);
	}

	package main;

	my @log;
	my $logger = My::AppLogger->new(array => \@log, level => 'debug');
	isa_ok($logger, 'My::AppLogger');
	isa_ok($logger, 'Log::Abstraction');

	$logger->info('subclass info');
	is(scalar(@log), 1,              'subclass method delegation works');
	is($log[0]{message}, 'subclass info', 'message correct via subclass');
};

# ============================================================
# 24. Internal message store populated for ALL backend types
# ============================================================

subtest 'internal messages() populated for every backend type' => sub {
	plan tests => 5;

	# coderef
	my $l1 = Log::Abstraction->new(logger => sub { }, level => 'debug');
	$l1->debug('coderef'); is(scalar(@{$l1->messages()}), 1, 'coderef backend populates messages()');

	# arrayref
	my @arr;
	my $l2 = Log::Abstraction->new(logger => \@arr, level => 'debug');
	$l2->debug('arrayref'); is(scalar(@{$l2->messages()}), 1, 'arrayref backend populates messages()');

	# string (file path)
	my $path = tmp_file();
	my $l3 = Log::Abstraction->new(logger => $path, level => 'debug');
	$l3->debug('filepath'); is(scalar(@{$l3->messages()}), 1, 'file-path backend populates messages()');

	# top-level file key
	my $path2 = tmp_file();
	my $l4 = Log::Abstraction->new(file => $path2, level => 'debug');
	$l4->debug('file key'); is(scalar(@{$l4->messages()}), 1, 'file key populates messages()');

	# top-level array key
	my @arr2;
	my $l5 = Log::Abstraction->new(array => \@arr2, level => 'debug');
	$l5->debug('array key'); is(scalar(@{$l5->messages()}), 1, 'array key populates messages()');
};

# ============================================================
# 25. format %callstack% token
# ============================================================

subtest 'format — %callstack% contains filename and line number' => sub {
	plan tests => 2;

	my $path = tmp_file();
	my @sink;
	my $logger = Log::Abstraction->new(
		file   => $path,
		array  => \@sink,
		level  => 'debug',
		format => '%callstack%',
	);
	$logger->debug('callstack test');
	my $content = slurp($path);
	like($content, qr/extended_tests\.t/, '%callstack% contains filename');
	like($content, qr/\d+/,               '%callstack% contains line number');
};

done_testing();
