#!/usr/bin/env perl
# t/journald.t -- Tests for the journald backend of Log::Abstraction
#
# Creates a temporary Unix-domain datagram socket to act as the journald
# receiver so these tests work on any platform without a real systemd.

use strict;
use warnings;

use Test::Most;
use Socket qw(AF_UNIX SOCK_DGRAM sockaddr_un);
use File::Temp qw(tempdir);

use Log::Abstraction;

# Unix-domain datagram sockets are not available on all platforms (notably
# Windows without the AF_UNIX feature enabled).  Skip the whole file rather
# than failing with a hard socket error inside a subtest.
{
	my $ok = eval {
		socket(my $probe, AF_UNIX, SOCK_DGRAM, 0) or die $!;
		close $probe;
		1;
	};
	plan skip_all => "Unix domain sockets not available: $@" unless $ok;
}

my $tmpdir   = tempdir(CLEANUP => 1);
my $SOCKPATH = "$tmpdir/journal.socket";

# ---------------------------------------------------------------------------
# Helper: bind a receiver socket, run $code, return the datagram received.
# Cleans up the socket file after each call so tests are independent.
# ---------------------------------------------------------------------------
sub with_receiver {
	my ($code) = @_;

	socket(my $recv, AF_UNIX, SOCK_DGRAM, 0) or die "socket: $!";
	bind($recv, sockaddr_un($SOCKPATH)) or die "bind: $!";

	$code->();

	my $data = '';
	recv($recv, $data, 65536, 0);
	close $recv;
	unlink $SOCKPATH;
	return $data;
}

# ---------------------------------------------------------------------------
# Parse a journald native-protocol datagram into a plain hash.
# Both text form (FIELD=VALUE\n) and binary form (FIELD\n<uint64le><VALUE>\n)
# are handled.
# ---------------------------------------------------------------------------
sub parse_journald {
	my ($data) = @_;

	my %fields;
	while(length($data)) {
		if($data =~ s/\A([A-Z0-9_]+)=([^\n]*)\n//) {
			$fields{$1} = $2;
		} elsif($data =~ s/\A([A-Z0-9_]+)\n//) {
			my $key = $1;
			# Binary-framed: 8-byte uint64-LE length, then value bytes, then \n
			my $len = unpack('Q<', substr($data, 0, 8, ''));
			my $val = substr($data, 0, $len, '');
			$data    =~ s/\A\n//;
			$fields{$key} = $val;
		} else {
			last;    # unexpected byte sequence; stop
		}
	}
	return %fields;
}

# ---------------------------------------------------------------------------
# 1. Basic dispatch: MESSAGE, PRIORITY, SYSLOG_IDENTIFIER are sent
# ---------------------------------------------------------------------------

subtest 'journald backend sends MESSAGE PRIORITY SYSLOG_IDENTIFIER' => sub {
	plan tests => 3;

	my $data = with_receiver(sub {
		my $logger = Log::Abstraction->new(
			level  => 'debug',
			logger => {
				journald => {
					socket     => $SOCKPATH,
					identifier => 'test-app',
				},
			},
		);
		$logger->info('hello journald');
	});

	my %f = parse_journald($data);
	is($f{MESSAGE},           'hello journald', 'MESSAGE field correct');
	is($f{PRIORITY},          6,                'PRIORITY=6 for info level');
	is($f{SYSLOG_IDENTIFIER}, 'test-app',       'SYSLOG_IDENTIFIER correct');
};

# ---------------------------------------------------------------------------
# 2. PRIORITY reflects the log level correctly
# ---------------------------------------------------------------------------

subtest 'PRIORITY integer matches syslog level for debug/warn/error' => sub {
	plan tests => 3;

	for my $pair ([debug => 7], [warn => 4], [error => 3]) {
		my ($level, $expected_priority) = @{$pair};

		my $data = with_receiver(sub {
			my $logger = Log::Abstraction->new(
				level  => $level,
				logger => { journald => { socket => $SOCKPATH } },
			);
			$logger->$level("$level message");
		});

		my %f = parse_journald($data);
		is($f{PRIORITY}, $expected_priority,
			"PRIORITY=$expected_priority for level=$level");
	}
};

# ---------------------------------------------------------------------------
# 3. Extra fields in the journald config hash are forwarded (uppercased)
# ---------------------------------------------------------------------------

subtest 'extra journald config fields are included in datagram' => sub {
	plan tests => 2;

	my $data = with_receiver(sub {
		my $logger = Log::Abstraction->new(
			level  => 'debug',
			logger => {
				journald => {
					socket      => $SOCKPATH,
					identifier  => 'test-app',
					CODE_FILE   => __FILE__,
				},
			},
		);
		$logger->debug('extra fields test');
	});

	my %f = parse_journald($data);
	ok(exists($f{CODE_FILE}),   'extra field CODE_FILE present in datagram');
	is($f{CODE_FILE}, __FILE__, 'CODE_FILE value matches');
};

# ---------------------------------------------------------------------------
# 4. journald coexists with other sub-backends in the same HASH logger
# ---------------------------------------------------------------------------

subtest 'journald and array sub-backends coexist' => sub {
	plan tests => 3;

	my @msgs;
	my $data = with_receiver(sub {
		my $logger = Log::Abstraction->new(
			level  => 'debug',
			logger => {
				array    => \@msgs,
				journald => { socket => $SOCKPATH },
			},
		);
		$logger->info('dual backend');
	});

	my %f = parse_journald($data);
	is($f{MESSAGE}, 'dual backend', 'journald received the message');
	is(scalar(@msgs), 1,            'array backend also received message');
	is($msgs[0]{message}, 'dual backend', 'array backend message text correct');
};

# ---------------------------------------------------------------------------
# 5. Missing / unwritable socket fails silently (carp, never croak)
# ---------------------------------------------------------------------------

subtest 'bad socket path does not croak' => sub {
	plan tests => 1;

	my $logger = Log::Abstraction->new(
		level  => 'debug',
		logger => { journald => { socket => '/nonexistent/journal.socket' } },
	);

	lives_ok(sub { $logger->info('silent fail test') },
		'unreachable socket path does not croak the application');
};

# ---------------------------------------------------------------------------
# 6. Message with embedded newlines is binary-framed; round-trip intact
# ---------------------------------------------------------------------------

subtest 'multi-line message survives binary framing' => sub {
	plan tests => 1;

	my $multiline = "line one\nline two\nline three";
	my $data = with_receiver(sub {
		my $logger = Log::Abstraction->new(
			level  => 'debug',
			logger => { journald => { socket => $SOCKPATH } },
		);
		$logger->debug($multiline);
	});

	my %f = parse_journald($data);
	is($f{MESSAGE}, $multiline, 'multi-line message round-trips through binary framing');
};

# ---------------------------------------------------------------------------
# 7. journald-only HASH logger does not trigger "don't know how" croak
# ---------------------------------------------------------------------------

subtest 'journald-only hash logger does not produce config-error croak' => sub {
	plan tests => 1;

	my $data = with_receiver(sub {
		lives_ok(sub {
			my $logger = Log::Abstraction->new(
				level  => 'debug',
				logger => { journald => { socket => $SOCKPATH } },
			);
			$logger->debug('only journald');
		}, 'journald-only hash does not croak');
	});
};

done_testing();
