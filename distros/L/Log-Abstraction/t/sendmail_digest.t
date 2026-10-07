#!/usr/bin/env perl
# t/sendmail_digest.t -- sendmail digest: messages held back by min_interval
# are sent with the next email instead of being dropped

use strict;
use warnings;

use Test::Needs 'Email::Sender::Transport::SMTP', 'Email::Simple';

use Test::Mockingbird;
use Test::Most;

use Log::Abstraction;

# The body of each email sent, with CRLF line endings undone
my @bodies;
my $fail = 0;
my $guard = Test::Mockingbird::mock_scoped('Email::Sender::Transport::SMTP::send_email' => sub {
	die "SMTP is down\n" if($fail);
	(my $body = $_[1]->get_body()) =~ s/\r\n/\n/g;
	$body =~ s/\n\z//;
	push @bodies, $body;
	return 1;
});

# A logger that emails errors, at most one per 300 seconds
sub mailer {
	my %sendmail = @_;
	return Log::Abstraction->new(level => 'debug', logger => {
		array    => [],
		sendmail => { to => 'ops@example.com', min_interval => 300, %sendmail },
	});
}

# Make the logger think its last email was sent long enough ago
sub interval_passes { $_[0]->{_last_email_sent} -= 301 }

subtest 'without digest, throttled messages are dropped' => sub {
	@bodies = ();
	my $log = mailer();
	$log->error($_) for qw(one two three);
	interval_passes($log);
	$log->error('four');
	is_deeply(\@bodies, ['one', 'four'], 'two and three were never sent');
	undef $log;
	is(scalar(@bodies), 2, 'nor sent when the logger is destroyed');
};

subtest 'with digest, they go out with the next email' => sub {
	@bodies = ();
	my $log = mailer(digest => 1);
	$log->error($_) for qw(one two three);
	is_deeply(\@bodies, ['one'], 'one email so far');

	interval_passes($log);
	$log->error('four');
	is_deeply(\@bodies, ['one', "two\nthree\nfour"], 'the next email has the held messages first');

	$log->error('five');
	is(scalar(@bodies), 2, 'the throttle starts again');
	interval_passes($log);
	$log->error('six');
	is($bodies[2], "five\nsix", 'and the digest was emptied');
};

subtest 'held lines use the sendmail format' => sub {
	@bodies = ();
	my $log = mailer(digest => 1, format => '%level%: %message%');
	$log->error('one');
	$log->warn('two');
	interval_passes($log);
	$log->critical('three');
	is_deeply(\@bodies, ['ERROR: one', "WARN: two\nCRITICAL: three"], 'formatted');
};

subtest 'held lines include structured fields' => sub {
	@bodies = ();
	my $log = mailer(digest => 1);
	$log->error('one');
	$log->error('two', { id => 2 });
	interval_passes($log);
	$log->error('three');
	is($bodies[1], "two id=2\nthree", 'as logfmt text');
};

subtest "only messages that pass the sendmail level are held" => sub {
	@bodies = ();
	my $log = mailer(digest => 1, level => 'error');
	$log->error('one');
	$log->info('ignored');
	$log->error('two');
	interval_passes($log);
	$log->error('three');
	is($bodies[1], "two\nthree", 'the info message is not in the digest');
};

subtest 'digest_max' => sub {
	@bodies = ();
	my $log = mailer(digest => 1, digest_max => 2);
	$log->error($_) for qw(one two three four five);
	interval_passes($log);
	$log->error('six');
	is($bodies[1], "two\nthree\n... and 2 more messages\nsix", 'the oldest are kept, the rest counted');

	$log->error($_) for qw(a b c);
	interval_passes($log);
	$log->error('d');
	is($bodies[2], "a\nb\n... and 1 more message\nd", 'one more message');

	$log->error('e');
	interval_passes($log);
	$log->error('f');
	is($bodies[3], "e\nf", 'the count was reset');
};

subtest 'the default digest_max is 100' => sub {
	@bodies = ();
	my $log = mailer(digest => 1);
	$log->error('first');
	$log->error("m$_") for 1..105;
	interval_passes($log);
	$log->error('last');
	my @lines = split(/\n/, $bodies[1]);
	is(scalar(@lines), 102, '100 held, the count and the new one');
	is($lines[100], '... and 5 more messages', 'the rest counted');
};

subtest 'flush' => sub {
	@bodies = ();
	my $log = mailer(digest => 1);
	is($log->flush(), $log, 'returns the logger');
	is(scalar(@bodies), 0, 'nothing sent when nothing is held');

	$log->error('one');
	$log->error('two');
	$log->error('three');
	$log->flush();
	is_deeply(\@bodies, ['one', "two\nthree"], 'held messages sent at once');
	$log->flush();
	is(scalar(@bodies), 2, 'and not again');

	$log->error('four');
	is(scalar(@bodies), 2, 'flush started the throttle again');

	my $plain = Log::Abstraction->new(logger => []);
	is($plain->flush(), $plain, 'a logger without sendmail can be flushed');

	local $@ = 'before';
	local $! = 2;
	$log->flush();
	is($@, 'before', '$@ unchanged');
	is($! + 0, 2, '$! unchanged');
};

subtest 'destroying the logger flushes the digest' => sub {
	@bodies = ();
	my $log = mailer(digest => 1);
	$log->error('one');
	$log->error('two');
	local $@ = 'before';
	undef $log;
	is_deeply(\@bodies, ['one', 'two'], 'held message sent');
	is($@, 'before', '$@ unchanged');
};

subtest 'a failed send keeps the messages' => sub {
	@bodies = ();
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $log = mailer(digest => 1);
	$log->error('one');
	$log->error('two');

	interval_passes($log);
	$fail = 1;
	$log->error('three');
	$fail = 0;
	is(scalar(@bodies), 1, 'not sent');
	like($warnings[0], qr/^Failed to send email: SMTP is down/, 'carped');

	$log->error('four');
	is_deeply(\@bodies, ['one', "two\nthree\nfour"],
		'the next email has them, sent at once as the interval is still over');
};

subtest 'without digest, a failed send loses the message as before' => sub {
	@bodies = ();
	local $SIG{__WARN__} = sub { };
	my $log = mailer();
	$fail = 1;
	$log->error('one');
	$fail = 0;
	$log->error('two');
	is_deeply(\@bodies, ['two'], 'one is gone');
};

subtest 'a clone starts with nothing held' => sub {
	@bodies = ();
	my $log = mailer(digest => 1);
	$log->error('one');
	$log->error('two');

	my $clone = $log->new();
	$clone->flush();
	is(scalar(@bodies), 1, 'the clone has nothing to send');
	undef $clone;
	is(scalar(@bodies), 1, 'nor when it is destroyed');

	$log->flush();
	is($bodies[1], 'two', 'the original still has its digest');
};

subtest 'digest_max is validated' => sub {
	for my $bad (0, -1, 'x', '1.5', '') {
		throws_ok(sub { mailer(digest => 1, digest_max => $bad) },
			qr/sendmail digest_max must be a positive integer, not '\Q$bad\E'/, "digest_max '$bad'");
	}
	lives_ok(sub { mailer(digest => 1, digest_max => 3) }, 'digest_max 3');
	lives_ok(sub { mailer(digest => 1, digest_max => undef) }, 'digest_max undef');
	lives_ok(sub { Log::Abstraction->new(logger => { array => [] }) }, 'no sendmail at all');
};

done_testing();
