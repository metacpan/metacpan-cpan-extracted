#!perl -w

use warnings;
use strict;
use Test::Most tests => 15;
use LWP::Protocol::https;
use Test::Timer;
use IO::Socket::INET;

BEGIN {
	use_ok('LWP::UserAgent::Throttled');
	use_ok('Time::HiRes');
}

THROTTLE: {
	SKIP: {
		my $s = IO::Socket::INET->new(
			PeerAddr => 'example.com:80',
			Timeout => 2	# Set low to try to catch slow machines
		);
		skip 'Responsive machine and an Internet connection are required for testing', 13 unless($s);

		skip 'Time::HiRes::usleep required for testing throttling', 13 unless(&Time::HiRes::d_usleep);

		diag('This will take some time because of sleeps');
		diag('Some tests will fail on slower machines and connections');

		my $ua = new_ok('LWP::UserAgent::Throttled');

		my $start = Time::HiRes::time();
		$ua->get('https://www.perl.org/');
		my $timetaken = Time::HiRes::time() - $start;
		skip('Responsive machine is required for testing', 12) if($timetaken >= 3);

		$Test::Timer::alarm = 20;

		$ua->timeout(15);
		$ua->env_proxy(1);
		$ua->max_redirect(0);

		is($ua->throttle(), undef, 'Giving no argument does something sensible');
		cmp_ok($ua->throttle('example.com'), '==', 0, 'Thottle value initialises to 0');
		$ua->throttle({ 'example.com' => 10 });
		cmp_ok($ua->throttle('example.com'), '==', 10, 'Can set throttle value');
		cmp_ok($ua->throttle('perl.org'), '==', 0, 'Thottle does not affect unrequested site');

		my $response;
		# Will fail on slow machines
		time_atmost(sub { $response = $ua->get('https://example.com/'); }, 8, 'should not be throttled');
		ok($response->is_success());

		$ua->ssl_opts(verify_hostname => 0);
		$start = Time::HiRes::time();
		# Will fail on slow machines
		time_atmost(sub { $response = $ua->get('https://www.perl.org/'); }, 8, 'should not be throttled');
		cmp_ok($response->is_success(), '!=', 0, 'Gets sucess from www.perl.org');

		sleep(8);

		$timetaken = Time::HiRes::time() - $start;	# Don't trust the return value from sleep

		SKIP: {
			if($timetaken >= 9) {
				diag("timetaken = $timetaken. Not testing throttling");
				skip("The system is too slow to run timing tests (timer = $timetaken)", 4);
			}
			time_between(sub { $response = $ua->get('http://example.com/'); }, 1, 6, 'should be throttled to 2 seconds, not 10');
			ok($response->is_success());

			time_atleast(sub { $response = $ua->get('http://example.com/'); }, 9, 'should be fully throttled');
			ok($response->is_success());
		}
	}
}
