#!/usr/bin/env perl

use strict;
use warnings;

use Test::Needs 'Email::Sender::Transport::SMTP';

use Test::Mockingbird;
use Test::Most;

BEGIN { use_ok('Log::Abstraction') }

my $config = {
	logger => {
		sendmail => {
			host => 'smtp.example.com',
			port => 25,
			to => 'alerts@example.com',
			from => 'logger@example.com',
			subject => 'Subject',
		}
	},
	level => 'info'
};

# Mock sendmail
my $called = 0;
Test::Mockingbird::mock('Email::Sender::Transport::SMTP', 'send_email', sub {
	my ($self, $email, $env) = @_;

	$called++;
	isa_ok($email, 'Email::Abstract', 'Email is correct object');
	like($email->as_string(), qr/Info message/, 'Message body looks correct');
	ok($email->get_header('Subject') eq 'Subject', 'Subject line is correct');
	ok($email->get_header('From') eq 'logger@example.com');
	ok($email->get_header('To') eq 'alerts@example.com');

	return 1;
});

# Instantiate and log
eval {
	my $log = Log::Abstraction->new($config);
	$log->debug('Debug message');
	$log->info('Info message');
	1;
} or do {
	fail("Log::Abstraction threw error: $@");
};

Test::Mockingbird::unmock('Email::Sender::Transport::SMTP', 'send_email');

cmp_ok($called, '==', 1, 'sendmail was called just once');

# ---------------------------------------------------------------------------
# Throttle: min_interval
# ---------------------------------------------------------------------------

subtest 'min_interval suppresses emails within cooldown' => sub {
	my $sent = 0;
	Test::Mockingbird::mock('Email::Sender::Transport::SMTP', 'send_email', sub { $sent++; return 1 });

	my $log = Log::Abstraction->new({
		logger => {
			sendmail => {
				host => 'localhost',
				to   => 'alerts@example.com',
				min_interval => 300,
			}
		},
		level => 'warning'
	});

	$log->warn('first warning');
	$log->warn('second warning — should be throttled');
	$log->warn('third warning — should be throttled');

	cmp_ok($sent, '==', 1, 'only one email sent despite three warn calls');

	Test::Mockingbird::unmock('Email::Sender::Transport::SMTP', 'send_email');
};

subtest 'no min_interval means every eligible message sends' => sub {
	my $sent = 0;
	Test::Mockingbird::mock('Email::Sender::Transport::SMTP', 'send_email', sub { $sent++; return 1 });

	my $log = Log::Abstraction->new({
		logger => {
			sendmail => {
				host => 'localhost',
				to   => 'alerts@example.com',
			}
		},
		level => 'warning'
	});

	$log->warn('first');
	$log->warn('second');

	cmp_ok($sent, '==', 2, 'both emails sent when no min_interval set');

	Test::Mockingbird::unmock('Email::Sender::Transport::SMTP', 'send_email');
};

subtest 'min_interval=0 does not throttle' => sub {
	my $sent = 0;
	Test::Mockingbird::mock('Email::Sender::Transport::SMTP', 'send_email', sub { $sent++; return 1 });

	my $log = Log::Abstraction->new({
		logger => {
			sendmail => {
				host => 'localhost',
				to   => 'alerts@example.com',
				min_interval => 0,
			}
		},
		level => 'warning'
	});

	$log->warn('first');
	$log->warn('second');

	cmp_ok($sent, '==', 2, 'both emails sent when min_interval is 0');

	Test::Mockingbird::unmock('Email::Sender::Transport::SMTP', 'send_email');
};

done_testing();
