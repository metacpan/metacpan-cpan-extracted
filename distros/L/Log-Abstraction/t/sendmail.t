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

done_testing();
