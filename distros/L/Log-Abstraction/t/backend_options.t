#!/usr/bin/env perl
# t/backend_options.t -- each backend's own 'level' and 'format' keys

use strict;
use warnings;

use File::Temp qw(tempdir);
use Socket qw(AF_UNIX SOCK_DGRAM sockaddr_un MSG_DONTWAIT);
use Test::Mockingbird;
use Test::Most;

use Log::Abstraction;

my $tmpdir = tempdir(CLEANUP => 1);
my $count  = 0;

# Read a file's lines, tolerating CRLF line endings on Windows
sub lines {
	my ($path) = @_;
	open(my $fin, '<', $path) or return;
	my @lines = map { s/\r?\n\z//r } <$fin>;
	close $fin;
	return @lines;
}

# A string filehandle and a sub returning what has been written to it, as lines
sub string_fd {
	my $out = '';
	open(my $fh, '>', \$out) or die $!;
	return ($fh, sub { return split(/\n/, $out) });
}

# Log one message at each level from debug to error
sub log_all {
	my ($log) = @_;
	$log->debug('d')->info('i')->warn('w')->error('e');
	return;
}

subtest 'level: logger hash file, fd and array' => sub {
	my $path = "$tmpdir/" . ++$count . '.log';
	my ($fh, $fd_lines) = string_fd();
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', format => '%message%', logger => {
		file  => { file => $path, level => 'info' },
		fd    => { fd => $fh, level => 'warning' },
		array => { array => \@array, level => 'error' },
	});
	log_all($log);

	is_deeply([ lines($path) ], ['i', 'w', 'e'], 'file: info and above');
	is_deeply([ $fd_lines->() ], ['w', 'e'], 'fd: warning and above');
	is_deeply([ map { $_->{message} } @array ], ['e'], 'array: error and above');
	is(scalar(@{$log->messages()}), 4, 'the history still has every message');
};

subtest 'level: top-level file, fd and array' => sub {
	my $path = "$tmpdir/" . ++$count . '.log';
	my ($fh, $fd_lines) = string_fd();
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', format => '%message%',
		file  => { file => $path, level => 'warning' },
		fd    => { fd => $fh, level => 'error' },
		array => { array => \@array, level => 'info' },
	);
	log_all($log);

	is_deeply([ lines($path) ], ['w', 'e'], 'file');
	is_deeply([ $fd_lines->() ], ['e'], 'fd');
	is_deeply([ map { $_->{message} } @array ], ['i', 'w', 'e'], 'array');
};

subtest 'level may be a syslog number, in any case' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => { array => { array => \@array, level => 4 } });
	log_all($log);
	is_deeply([ map { $_->{message} } @array ], ['w', 'e'], '4 is warning');

	@array = ();
	$log = Log::Abstraction->new(level => 'debug', logger => { array => { array => \@array, level => 'ERROR' } });
	log_all($log);
	is_deeply([ map { $_->{message} } @array ], ['e'], "'ERROR'");
};

subtest "the logger's level is applied first" => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'error', logger => { array => { array => \@array, level => 'debug' } });
	log_all($log);
	is_deeply([ map { $_->{message} } @array ], ['e'], 'a backend level can only narrow it');
};

subtest 'format: file and fd' => sub {
	my $path = "$tmpdir/" . ++$count . '.log';
	my ($fh, $fd_lines) = string_fd();
	my $log = Log::Abstraction->new(level => 'info', format => 'top %message%', logger => {
		file => { file => $path, format => 'file %level% %message%' },
		fd   => { fd => $fh },
	});
	$log->info('m');

	is_deeply([ lines($path) ], ['file INFO m'], "the file's own format");
	is_deeply([ $fd_lines->() ], ['top m'], "the fd uses the logger's");
};

subtest 'format: json for one backend only' => sub {
	require JSON::PP;
	my ($json_fh, $json_lines) = string_fd();
	my ($text_fh, $text_lines) = string_fd();
	my $log = Log::Abstraction->new(level => 'info', format => '%message%',
		fd => { fd => $json_fh, format => 'json' },
		logger => { fd => $text_fh },
	);
	$log->info('m', { k => 'v' });

	my $obj = JSON::PP->new->decode(($json_lines->())[0]);
	is($obj->{message}, 'm', 'JSON line');
	is_deeply($obj->{fields}, { k => 'v' }, 'with the fields');
	is_deeply([ $text_lines->() ], ['m k=v'], 'the other fd is text');
};

subtest 'format: array' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'info',
		logger => { array => { array => \@array, format => '%level%|%message%' } });
	$log->info('m', { k => 'v' });
	is($array[0]{message}, 'INFO|m k=v', 'the message is the formatted line');
	is($array[0]{level}, 'info', 'level unchanged');
	is_deeply($array[0]{fields}, { k => 'v' }, 'fields kept');

	@array = ();
	Log::Abstraction->new(level => 'info', format => '%level%|%message%', logger => { array => \@array })->info('m');
	is($array[0]{message}, 'm', "the logger's format doesn't apply to an array");
};

subtest 'level and format: syslog' => sub {
	my (@sent, @socks);
	my $g1 = Test::Mockingbird::mock_scoped('Sys::Syslog::openlog' => sub { 1 });
	my $g2 = Test::Mockingbird::mock_scoped('Sys::Syslog::syslog' => sub { push @sent, $_[2] });
	my $g3 = Test::Mockingbird::mock_scoped('Sys::Syslog::closelog' => sub { 1 });
	my $g4 = Test::Mockingbird::mock_scoped('Sys::Syslog::setlogsock' => sub { push @socks, { %{$_[0]} } });

	my $log = Log::Abstraction->new(level => 'debug', script_name => 'bo', logger => {
		syslog => { level => 'warning', format => '%level%: %message%', host => 'loghost' },
	});
	log_all($log);
	is_deeply(\@sent, ['WARN: w', 'ERROR: e'], 'warning and above, formatted');
	is_deeply(\@socks, [ { host => 'loghost' } ], 'level and format are not passed to setlogsock');
	undef $log;
};

subtest 'level and format: journald' => sub {
	my $ok = eval { socket(my $probe, AF_UNIX, SOCK_DGRAM, 0) or die "$!\n"; close $probe; 1 };
	plan skip_all => 'Unix domain sockets not available' unless($ok);

	my $sockpath = "$tmpdir/journal.socket";
	socket(my $recv, AF_UNIX, SOCK_DGRAM, 0) or die "socket: $!";
	bind($recv, sockaddr_un($sockpath)) or die "bind: $!";

	my $log = Log::Abstraction->new(level => 'debug', logger => {
		journald => { socket => $sockpath, level => 'warning', format => '[%level%] %message%', app => 'a' },
	});
	$log->info('dropped');
	$log->warn('kept');

	my @datagrams;
	while(1) {
		my $data = '';
		last unless(defined(recv($recv, $data, 65536, MSG_DONTWAIT)) && length($data));
		push @datagrams, $data;
	}
	close $recv;
	unlink $sockpath;

	is(scalar(@datagrams), 1, 'only the warning was sent');
	like($datagrams[0], qr/^MESSAGE=\[WARN\] kept$/m, 'MESSAGE is formatted');
	like($datagrams[0], qr/^APP=a$/m, 'other keys are still fields');
	unlike($datagrams[0], qr/^(?:LEVEL|FORMAT)=/m, 'level and format are not sent as fields');
};

subtest 'level and format: sendmail' => sub {
	eval { require Email::Sender::Transport::SMTP; require Email::Simple; 1 }
		or plan skip_all => 'Email::Sender not installed';

	my @bodies;
	my $guard = Test::Mockingbird::mock_scoped('Email::Sender::Transport::SMTP::send_email' => sub {
		push @bodies, $_[1]->get_body();
		return 1;
	});
	my $log = Log::Abstraction->new(level => 'debug', logger => {
		sendmail => { to => 'ops@example.com', level => 'error', format => 'ALERT %message%' },
	});
	log_all($log);
	is(scalar(@bodies), 1, 'only the error was emailed');
	like($bodies[0], qr/^ALERT e\s*$/, 'the body is formatted');
};

subtest 'the plain forms are unchanged' => sub {
	my $path = "$tmpdir/" . ++$count . '.log';
	my ($fh, $fd_lines) = string_fd();
	my @array;
	my $log = Log::Abstraction->new(level => 'info', format => '%message%',
		logger => { file => $path, fd => $fh, array => \@array });
	$log->info('m');
	is_deeply([ lines($path) ], ['m'], 'file');
	is_deeply([ $fd_lines->() ], ['m'], 'fd');
	is_deeply(\@array, [ { level => 'info', message => 'm' } ], 'array');
};

subtest 'a top-level fd alone is a backend: no Log4perl fallback' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	for my $form ('plain', 'hash') {
		my ($fh, $fd_lines) = string_fd();
		my $fd = ($form eq 'plain') ? $fh : { fd => $fh };
		my $log = Log::Abstraction->new(level => 'info', format => '%message%', fd => $fd);

		ok(!defined($log->{logger}), "$form fd: no default logger");
		lives_ok(sub { $log->info('i')->warn('w')->error('e') }, "$form fd: error() does not croak");
		is_deeply([ $fd_lines->() ], ['i', 'w', 'e'], "$form fd: messages go to the fd");
	}
	is_deeply(\@warnings, [], 'and warn() does not carp');

	isa_ok(Log::Abstraction->new()->{logger}, 'Log::Log4perl::Logger', 'with no backend at all, Log4perl');
};

subtest 'invalid options croak' => sub {
	my ($fh) = string_fd();
	my %dest = (file => "$tmpdir/x.log", fd => $fh, array => []);

	for my $name (qw(file fd array)) {
		throws_ok(sub { Log::Abstraction->new(logger => { $name => { level => 'info' } }) },
			qr/the $name hash needs a '$name' key/, "logger hash $name without a destination");
		throws_ok(sub { Log::Abstraction->new(logger => [], $name => { format => 'json' }) },
			qr/the $name hash needs a '$name' key/, "top-level $name without a destination");
		throws_ok(sub { Log::Abstraction->new(logger => { $name => { $name => $dest{$name}, level => 'loud' } }) },
			qr/invalid $name level 'loud'/, "$name: bad level");
		throws_ok(sub { Log::Abstraction->new(logger => { $name => { $name => $dest{$name}, format => '' } }) },
			qr/the $name format must be a non-empty string/, "$name: empty format");
	}
	throws_ok(sub { Log::Abstraction->new(logger => { journald => { level => 9 } }) },
		qr/invalid journald level '9'/, 'journald: bad level');
	throws_ok(sub { Log::Abstraction->new(logger => { journald => { format => undef } }) },
		qr/the journald format must be a non-empty string/, 'journald: undef format');
	throws_ok(sub { Log::Abstraction->new(logger => { sendmail => { to => 'x@example.com', format => [] } }) },
		qr/the sendmail format must be a non-empty string/, 'sendmail: reference as format');
	throws_ok(sub { Log::Abstraction->new(script_name => 's', logger => { syslog => { level => 'nope' } }) },
		qr/invalid syslog level 'nope'/, 'syslog: bad level');
};

done_testing();
