#!/usr/bin/env perl
# t/namespace.t -- no imported functions in the modules' namespaces
#
# Imported functions become methods: $log->croak, $log->syslog and so on
# used to work by accident.  Only the public API, and private _subs,
# should be callable on a logger.

use strict;
use warnings;

use Test::Most;

use Log::Abstraction;

# Functions the modules use from other packages, which must not be imported
my @foreign = qw(
	carp croak confess cluck blessed strftime
	openlog closelog syslog setlogsock setlogmask
	sendmail Readonly
);

subtest 'Log::Abstraction' => sub {
	my $log = Log::Abstraction->new(logger => []);
	for my $name (@foreign) {
		ok(!$log->can($name), "no $name method");
	}
};

subtest 'not even after sending an email' => sub {
	eval { require Email::Sender::Transport::SMTP; require Email::Simple; 1 }
		or plan skip_all => 'Email::Sender not installed';
	require Test::Mockingbird;
	my $guard = Test::Mockingbird::mock_scoped('Email::Sender::Transport::SMTP::send_email' => sub { 1 });

	my $log = Log::Abstraction->new(level => 'error', logger => { sendmail => { to => 'ops@example.com' } });
	$log->error('mail');
	ok(!$log->can('sendmail'), 'no sendmail method');
};

subtest 'the public API is all that is left' => sub {
	no strict 'refs';
	my @subs = sort grep { defined(&{"Log::Abstraction::$_"}) && !/^_/ } keys %Log::Abstraction::;
	is_deeply(\@subs, [ sort qw(
		DESTROY new level messages flush
		trace debug info notice warn error fatal critical alert emergency
		is_trace is_debug is_info is_notice is_warn is_error is_critical is_alert is_emergency
	) ], 'Log::Abstraction') or diag(explain(\@subs));
};

subtest 'Log::Any::Adapter::Abstraction' => sub {
	plan skip_all => 'Log::Any not installed' unless(eval { require Log::Any::Adapter::Abstraction; 1 });
	for my $name (@foreign) {
		ok(!Log::Any::Adapter::Abstraction->can($name), "no $name method");
	}
};

done_testing();
