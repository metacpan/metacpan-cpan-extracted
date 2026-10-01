#!/usr/bin/env perl

# Regression tests for the issues found by the 0.35 gap analysis

use strict;
use warnings;

use File::Temp qw(tempdir);
use Socket qw(AF_UNIX SOCK_DGRAM sockaddr_un MSG_DONTWAIT);
use Test::Mockingbird;
use Test::Most;

BEGIN { use_ok('Log::Abstraction') }

my $tmpdir = tempdir(CLEANUP => 1);
my $file_count = 0;

sub tmp_file { return $tmpdir . '/log' . ++$file_count . '.txt' }

# Read raw bytes (to check the UTF-8 encoding), then undo the CRLF line
# endings that text-mode output produces on Windows
sub slurp {
	my $path = $_[0];
	open(my $fh, '<:raw', $path) or die "$path: $!";
	local $/;
	my $content = <$fh>;
	$content =~ s/\r\n/\n/g;
	return $content;
}

# Mock everything syslog touches; returns the guards and a ref to the calls
sub mock_syslog {
	my %calls = (syslog => [], closelog => 0, openlog => 0);
	my @guards = (
		mock_scoped('Log::Abstraction::openlog' => sub { $calls{openlog}++ }),
		mock_scoped('Log::Abstraction::setlogsock' => sub { }),
		mock_scoped('Sys::Syslog::setlogsock' => sub { }),
		mock_scoped('Sys::Syslog::syslog' => sub { push @{$calls{syslog}}, [@_] }),
		mock_scoped('Sys::Syslog::closelog' => sub { $calls{closelog}++ }),
	);
	return (\@guards, \%calls);
}

# ---------------------------------------------------------------------------
# level()
# ---------------------------------------------------------------------------

subtest 'level() setter is case-insensitive' => sub {
	my $logger = Log::Abstraction->new(logger => []);
	is($logger->level('DEBUG'), $logger, 'level("DEBUG") returns $self');
	is($logger->level(), 7, 'level set to debug');
	is($logger->level('Warning')->level(), 4, 'mixed case accepted');
};

subtest 'trace shares the debug threshold' => sub {
	my @log;
	my $logger = Log::Abstraction->new(logger => \@log, level => 'debug');
	$logger->trace('t');
	is(scalar(@log), 1, 'trace emitted at debug level');

	@log = ();
	$logger->level('info');
	$logger->trace('t');
	is(scalar(@log), 0, 'trace dropped at info level');
};

# ---------------------------------------------------------------------------
# Construction-time validation
# ---------------------------------------------------------------------------

subtest 'invalid sub-backend configuration croaks in new()' => sub {
	throws_ok(
		sub { Log::Abstraction->new(logger => { syslog => { level => 'loud' } }, script_name => 'x') },
		qr/invalid syslog level 'loud'/,
		'bad syslog level',
	);
	throws_ok(
		sub { Log::Abstraction->new(logger => { syslog => { level => 9 } }, script_name => 'x') },
		qr/invalid syslog level '9'/,
		'syslog level number out of range',
	);
	throws_ok(
		sub { Log::Abstraction->new(logger => { sendmail => { to => 'a@b.com', level => 'warnx' } }) },
		qr/invalid sendmail level 'warnx'/,
		'bad sendmail level',
	);
	throws_ok(
		sub { Log::Abstraction->new(logger => { sendmail => { host => 'localhost' } }) },
		qr/sendmail backend needs a 'to' address/,
		'sendmail without to',
	);
	throws_ok(
		sub { Log::Abstraction->new(logger => { journald => { 'my-field' => 1 } }) },
		qr/invalid journald field name 'my-field'/,
		'journald field with a hyphen',
	);
	throws_ok(
		sub { Log::Abstraction->new(logger => { journald => { _trusted => 1 } }) },
		qr/invalid journald field name '_trusted'/,
		'journald field starting with an underscore',
	);
	lives_ok(
		sub { Log::Abstraction->new(logger => { journald => { app_version => 1, socket => '/x', identifier => 'y' } }) },
		'valid journald field and reserved keys accepted',
	);
	throws_ok(
		sub { Log::Abstraction->new(logger => [], max_messages => -1) },
		qr/max_messages must be a non-negative integer/,
		'negative max_messages',
	);
};

# ---------------------------------------------------------------------------
# Message history cap
# ---------------------------------------------------------------------------

subtest 'max_messages caps the history' => sub {
	my $logger = Log::Abstraction->new(logger => [], level => 'debug', max_messages => 3);
	$logger->info("m$_") for 1..10;
	is_deeply(
		[ map { $_->{message} } @{$logger->messages()} ],
		[qw(m8 m9 m10)],
		'only the newest three entries are kept',
	);

	my $none = Log::Abstraction->new(logger => [], level => 'debug', max_messages => 0);
	$none->info('x');
	is(scalar(@{$none->messages()}), 0, 'max_messages => 0 keeps no history');

	my $unlimited = Log::Abstraction->new(logger => [], level => 'debug');
	$unlimited->info('x') for 1..50;
	is(scalar(@{$unlimited->messages()}), 50, 'unlimited by default');
};

# ---------------------------------------------------------------------------
# syslog
# ---------------------------------------------------------------------------

subtest 'syslog level may be a name' => sub {
	my ($guards, $calls) = mock_syslog();
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	my $logger = Log::Abstraction->new(
		logger      => { syslog => { level => 'warning' } },
		level       => 'debug',
		script_name => 'regress',
	);
	$logger->info('dropped');
	$logger->error('sent');

	is(scalar(@{$calls->{syslog}}), 1, 'only the message at or above warning is sent');
	is($calls->{syslog}[0][2], 'sent', 'the error message reached syslog');
	is(scalar(@warnings), 0, 'no "isn\'t numeric" warning');
};

subtest 'syslog message is passed through %s and joined like other backends' => sub {
	my ($guards, $calls) = mock_syslog();

	my $logger = Log::Abstraction->new(
		logger      => { syslog => {} },
		level       => 'debug',
		script_name => 'regress',
	);
	$logger->info('100% done, errno %m, ', 'second part');

	my ($priority, $format, @args) = @{$calls->{syslog}[0]};
	is($format, '%s', "format argument is '%s'");
	is($args[0], '100% done, errno %m, second part', 'message joined without a separator and passed literally');
};

subtest 'syslog script_name detected for a logger hash' => sub {
	my $logger = Log::Abstraction->new(logger => { syslog => {} });
	ok(defined($logger->{script_name}) && length($logger->{script_name}), 'script_name set from $0');
};

subtest 'syslog connection is only closed by the last instance' => sub {
	my ($guards, $calls) = mock_syslog();

	my $first = Log::Abstraction->new(logger => { syslog => {} }, script_name => 'a');
	my $second = Log::Abstraction->new(logger => { syslog => {} }, script_name => 'b');
	$first->warn('one');
	$second->warn('two');
	my $clone = $second->new();

	undef $first;
	is($calls->{closelog}, 0, 'closelog not called while other instances are open');
	undef $second;
	is($calls->{closelog}, 0, 'closelog not called while the clone is open');
	undef $clone;
	is($calls->{closelog}, 1, 'closelog called when the last instance goes');
};

# ---------------------------------------------------------------------------
# sendmail
# ---------------------------------------------------------------------------

subtest 'sendmail level is case-insensitive and body joined consistently' => sub {
	eval { require Email::Sender::Transport::SMTP; require Email::Simple; 1 }
		or plan skip_all => 'Email::Sender not installed';

	my @bodies;
	my $guard = mock_scoped('Email::Sender::Transport::SMTP::send_email' => sub {
		my ($self, $email) = @_;
		push @bodies, $email->get_body();
		return 1;
	});

	my $logger = Log::Abstraction->new(
		logger => { sendmail => { to => 'alerts@example.com', level => 'WARN' } },
		level  => 'debug',
	);
	$logger->info('not emailed');
	$logger->warn('a', 'b');

	is(scalar(@bodies), 1, 'only the warning was emailed');
	like($bodies[0], qr/^ab\s*$/, 'body joined without a separator');
};

# ---------------------------------------------------------------------------
# warn/error and Carp
# ---------------------------------------------------------------------------

subtest 'warn/error as a class method on a subclass' => sub {
	{
		package Regress::Sub;
		our @ISA = ('Log::Abstraction');
	}
	my @carps;
	local $SIG{__WARN__} = sub { push @carps, $_[0] };

	lives_ok(sub { Regress::Sub->warn('class warn') }, 'subclass warn() as class method lives');
	like(join('', @carps), qr/class warn/, 'and carps');
	throws_ok(sub { Regress::Sub->error('class error') }, qr/class error/, 'subclass error() croaks');
};

subtest 'carp_on_warn respects the level threshold' => sub {
	my @carps;
	local $SIG{__WARN__} = sub { push @carps, $_[0] };

	my $quiet = Log::Abstraction->new(logger => [], level => 'error', carp_on_warn => 1);
	$quiet->warn('filtered');
	is(scalar(@carps), 0, 'no carp for a warning below the threshold');

	my $loud = Log::Abstraction->new(logger => [], level => 'warning', carp_on_warn => 1);
	$loud->warn('shown');
	like(join('', @carps), qr/shown/, 'carp for a warning at the threshold');
};

subtest 'top-level fd counts as a backend' => sub {
	my $buffer = '';
	open(my $fd, '>', \$buffer) or die $!;
	my @carps;
	local $SIG{__WARN__} = sub { push @carps, $_[0] };

	my $logger = Log::Abstraction->new(array => [], fd => $fd);
	delete $logger->{array};    # leave fd as the only backend
	delete $logger->{logger};
	lives_ok(sub { $logger->error('to fd') }, 'error() does not croak with an fd backend');
	is(scalar(@carps), 0, 'and does not carp');
	like($buffer, qr/to fd/, 'message written to fd');
};

# ---------------------------------------------------------------------------
# Text format: line breaks and Unicode
# ---------------------------------------------------------------------------

subtest 'line breaks in a message are indented' => sub {
	my $path = tmp_file();
	my $logger = Log::Abstraction->new(file => $path, array => [], level => 'debug', format => '%level%> %message%');
	$logger->warn("first\nERROR> forged\r\nthird");
	is(slurp($path), "WARN> first\n\tERROR> forged\n\tthird\n", 'continuation lines start with a tab');
	is($logger->messages()->[0]{message}, "first\nERROR> forged\r\nthird", 'history keeps the original text');
};

subtest 'Unicode messages are written as UTF-8 without warnings' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };
	my $text = "caf\x{e9} \x{263a}";
	my $utf8 = "caf\xc3\xa9 \xe2\x98\xba";

	my $path = tmp_file();
	Log::Abstraction->new(file => $path, array => [], level => 'debug', format => '%message%')->info($text);
	is(slurp($path), "$utf8\n", 'file contains UTF-8');

	my $raw = '';
	open(my $fd, '>', \$raw) or die $!;
	Log::Abstraction->new(logger => { fd => $fd }, level => 'debug', format => '%message%')->info($text);
	close $fd;
	is($raw, "$utf8\n", 'raw fd receives UTF-8');

	my $layered = '';
	open(my $efd, '>:encoding(UTF-8)', \$layered) or die $!;
	Log::Abstraction->new(logger => { fd => $efd }, level => 'debug', format => '%message%')->info($text);
	close $efd;
	is($layered, "$utf8\n", 'fd with an encoding layer is not double-encoded');

	my $json_path = tmp_file();
	Log::Abstraction->new(file => $json_path, array => [], level => 'debug', format => 'json')->info($text);
	like(slurp($json_path), qr/"message":"\Q$utf8\E"/, 'JSON output is UTF-8');

	is(scalar(@warnings), 0, 'no "Wide character" warnings') or diag(@warnings);
};

# ---------------------------------------------------------------------------
# journald
# ---------------------------------------------------------------------------

subtest 'journald failures carp once until a send succeeds' => sub {
	my @carps;
	local $SIG{__WARN__} = sub { push @carps, $_[0] };

	my $logger = Log::Abstraction->new(
		logger => { journald => { socket => "$tmpdir/no-such.socket" } },
		level  => 'debug',
	);
	$logger->info("m$_") for 1..5;
	is(scalar(grep { /journald send failed/ } @carps), 1, 'five failures, one carp');
};

subtest 'oversized journald message is truncated' => sub {
	plan skip_all => 'large Unix datagrams are only reliable on Linux' if($^O ne 'linux');
	my $ok = eval { socket(my $probe, AF_UNIX, SOCK_DGRAM, 0) or die $!; 1 };
	plan skip_all => 'Unix domain sockets not available' unless $ok;

	my $sockpath = "$tmpdir/big.socket";
	socket(my $recv, AF_UNIX, SOCK_DGRAM, 0) or die "socket: $!";
	bind($recv, sockaddr_un($sockpath)) or die "bind: $!";

	my @carps;
	local $SIG{__WARN__} = sub { push @carps, $_[0] };
	my $logger = Log::Abstraction->new(logger => { journald => { socket => $sockpath } }, level => 'debug');
	$logger->info('x' x 300_000);

	# Non-blocking, so a failed send fails the test rather than hanging it
	my $data = '';
	recv($recv, $data, 1_000_000, MSG_DONTWAIT);
	close $recv;

	is(scalar(@carps), 0, 'send succeeded') or diag(@carps);
	cmp_ok(length($data), '<=', 200_000, 'datagram within the limit');
	like($data, qr/x \[truncated\]\nPRIORITY=/, 'message ends with the truncation marker');
};

# ---------------------------------------------------------------------------
# Format-token injection (0.35 security fix) through the default format
# ---------------------------------------------------------------------------

subtest 'tokens in a message are not expanded with the default format' => sub {
	local $ENV{LA_REGRESS_SECRET} = 'leaked';
	my $path = tmp_file();
	Log::Abstraction->new(file => $path, array => [], level => 'debug')->info('%env_LA_REGRESS_SECRET%');
	unlike(slurp($path), qr/leaked/, 'environment variable not leaked');
};

done_testing();
