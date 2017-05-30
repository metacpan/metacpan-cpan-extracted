#!perl -w

use warnings;
use strict;
use Test::Most tests => 14;

BEGIN {
	use_ok('LWP::UserAgent::Throttled');
	use_ok('Test::Timer');
}

THROTTLE: {
	diag('This will take some time because of sleeps');

	my $ua = new_ok('LWP::UserAgent::Throttled');

	$Test::Timer::alarm = 20;

	$ua->timeout(15);
	$ua->env_proxy(1);

	ok($ua->throttle('search.cpan.org') == 0);
	$ua->throttle({ 'search.cpan.org' => 10 });
	ok($ua->throttle('search.cpan.org') == 10);
	ok($ua->throttle('perl.org') == 0);

	my $response;
	time_atmost(sub { $response = $ua->get('http://search.cpan.org/'); }, 8, 'should not be throttled');
	ok($response->is_success());

	time_atmost(sub { $response = $ua->get('http://www.perl.org/'); }, 8, 'should not be throttled');
	ok($response->is_success());
	sleep(8);

	time_between(sub { $response = $ua->get('http://search.cpan.org/'); }, 1, 6, 'should be throttled to 2 seconds, not 10');
	ok($response->is_success());

	time_atleast(sub { $response = $ua->get('http://search.cpan.org/'); }, 9, 'should be fully throttled');
	ok($response->is_success());
}
