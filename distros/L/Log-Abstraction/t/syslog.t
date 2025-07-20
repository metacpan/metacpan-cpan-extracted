#!/usr/bin/env perl

use strict;
use warnings;

use Sys::Syslog;
use Test::Mockingbird;
use Test::Most;

BEGIN { use_ok('Log::Abstraction') }

my $config = {
	logger => {
		syslog => { }
	},
	level => 'info'
};

# Mock sendmail
my $called = 0;
Test::Mockingbird::mock('Sys::Syslog', 'syslog', sub {
	my ($priority, $format, @args) = @_;

	
	$called++;
	cmp_ok($format, 'eq', 'Info message', 'Message body looks correct');

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

Test::Mockingbird::unmock('Sys::Syslog', 'syslog');

cmp_ok($called, '==', 1, 'sendmail was called just once');

done_testing();
