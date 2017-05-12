#!perl -w

use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings;

BEGIN {
	use_ok('Log::Dispatch::Email::Sendmail');
}

# Based on Log::Dispatch/t/01-basic.t
SKIP: {
	my $email_address;

	if($ENV{LOG_DISPATCH_TEST_EMAIL}) {
		$email_address = $ENV{LOG_DISPATCH_TEST_EMAIL};
	}

	skip "Cannot do Sendmail tests", 1
		unless defined($email_address);

	my $dispatch = Log::Dispatch->new();

	$dispatch->add(
		Log::Dispatch::Email::Sendmail->new(
			name	=> 'Log::Dispatch::Email::Sendmail',
			min_level => 'debug',
			to	=> $email_address,
			subject	=> 'Log::Dispatch::Email::Sendmail test suite'
		)
	);

	$dispatch->log(
		level => 'emerg',
		message =>
			"Log::Dispatch::Email::Sendmail test - If you can read this then the test succeeded (PID $$)"
	);

	diag(
		"Sending email with Log::Dispatch::Email::Sendmail to $email_address.\nIf you get it then the test succeeded (PID $$)\n"
	);
	undef $dispatch;

	ok(1, 'sent email via MailSendmail');
}
