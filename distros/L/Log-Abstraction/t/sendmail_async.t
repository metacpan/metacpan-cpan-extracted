#!/usr/bin/env perl
# t/sendmail_async.t -- sendmail's async option: emails sent by a child
# process, so that the log call doesn't wait for the SMTP server

use strict;
use warnings;

use File::Temp qw(tempdir);
use POSIX ();
use Test::Needs 'Email::Sender::Transport::SMTP', 'Email::Simple';

use Test::Mockingbird;
use Test::Most;

# Must come before any test, or the harness reports "Bad plan"
BEGIN {
	if($^O eq 'MSWin32') {
		plan skip_all => "async sends synchronously on $^O";
	}
}

use Log::Abstraction;

my $tmpdir = tempdir(CLEANUP => 1);
my $count  = 0;

# The children write what they send here, as "pid body" lines, since the
# parent can't see what a mock in the child records
my $sent_file;
my $gate;    # if set, a handle the child reads a line from before sending
my $guard = Test::Mockingbird::mock_scoped('Email::Sender::Transport::SMTP::send_email' => sub {
	(my $body = $_[1]->get_body()) =~ s/\r\n/\n/g;
	$body =~ s/\n\z//;
	readline($gate) if($gate);
	die "SMTP is down\n" if($body =~ /FAIL/);
	open(my $fout, '>>', $sent_file) or die "$sent_file: $!";
	print $fout "$$ ", join('|', split(/\n/, $body)), "\n";
	close $fout;
	return 1;
});

# Wait for every child, so that what they sent is in $sent_file
sub wait_children { 1 while(waitpid(-1, 0) > 0) }

# What the children sent: [ pid, body ] pairs
sub sent {
	open(my $fin, '<', $sent_file) or return ();
	my @sent = map { chomp; [ split(/ /, $_, 2) ] } <$fin>;
	close $fin;
	return @sent;
}

sub mailer {
	my %sendmail = @_;
	$sent_file = "$tmpdir/sent" . ++$count;
	return Log::Abstraction->new(level => 'debug', logger => {
		sendmail => { to => 'ops@example.com', level => 'error', async => 1, %sendmail },
	});
}

subtest 'the log call does not wait for the email' => sub {
	my $log = mailer();
	pipe(my $read, my $write) or die "pipe: $!";
	$gate = $read;

	local $SIG{ALRM} = sub { die "timed out: the log call waited for the child\n" };
	alarm(10);
	lives_ok(sub { $log->error('disk full') }, 'returns while the SMTP server is "busy"');
	alarm(0);
	is_deeply([ sent() ], [], 'nothing sent yet');

	$gate = undef;
	close $read;
	print $write "go\n";
	close $write;
	wait_children();
	my @sent = sent();
	is(scalar(@sent), 1, 'then the child sends it');
	isnt($sent[0][0], $$, 'from another process');
	is($sent[0][1], 'disk full', 'the message');
};

subtest 'digest and min_interval' => sub {
	my $log = mailer(min_interval => 300, digest => 1);
	$log->error('one');
	ok($log->{_last_email_sent}, 'an async send starts the interval');
	$log->error('two')->error('three');
	is_deeply($log->{_email_digest}, ['two', 'three'], 'later messages are held');
	$log->flush();
	ok(!$log->{_email_digest}, 'flush() hands them to a child');
	wait_children();
	# The two children run at the same time, so either may finish first
	is_deeply([ sort map { $_->[1] } sent() ], ['one', 'two|three'], 'both emails sent');
};

subtest 'a failed send is carped by the child' => sub {
	my $log = mailer(digest => 1);
	my $stderr = "$tmpdir/stderr";
	{
		# The child inherits this handler, so each warning says which
		# process gave it
		local $SIG{__WARN__} = sub { print STDERR "$$: @_" };
		open(my $saved, '>&', \*STDERR) or die "dup: $!";
		open(STDERR, '>', $stderr) or die "$stderr: $!";
		my $ok = eval { $log->error('FAIL now'); 1 };
		wait_children();
		open(STDERR, '>&', $saved) or die "restore: $!";
		ok($ok, 'the log call does not die');
	}
	open(my $fin, '<', $stderr) or die "$stderr: $!";
	my @warnings = split(/^(?=\d+: )/m, do { local $/; <$fin> });
	is(scalar(@warnings), 1, 'one warning') or diag(@warnings);
	like($warnings[0], qr/^(\d+): Failed to send email: SMTP is down/, 'the carp');
	isnt(($warnings[0] =~ /^(\d+)/)[0], $$, 'from the child');
	ok(!$log->{_email_digest}, 'the message is not held');
};

subtest 'host and port are checked in the log call' => sub {
	my $log = mailer(host => 'bad host;');
	throws_ok(sub { $log->error('x') }, qr/Invalid SMTP host/, 'bad host croaks');
	$log = mailer(port => 70_000);
	throws_ok(sub { $log->error('x') }, qr/Invalid SMTP port/, 'bad port croaks');
};

subtest 'finished children are reaped' => sub {
	my $log = mailer();
	$log->error('first');
	my $pid;
	for(1 .. 100) {    # up to 10 seconds
		last if(($pid) = map { $_->[0] } sent());
		select(undef, undef, undef, 0.1);
	}
	ok($pid, 'the first child has sent');

	# Send until the first child had exited by the time of a send: then
	# that send reaped it, and waitpid finds no such child.  (If it hadn't
	# exited yet, waitpid returns 0; if the send didn't reap it, its pid)
	my $status;
	for(1 .. 100) {
		$log->error('again');
		last if(($status = waitpid($pid, POSIX::WNOHANG())) != 0);
		select(undef, undef, undef, 0.1);
	}
	is($status, -1, 'it was reaped by a later send');
	wait_children();

	$log->error('third');
	wait_children();
	undef $log;
	pass('a logger destroyed after its children were reaped by the program');
};

done_testing();
