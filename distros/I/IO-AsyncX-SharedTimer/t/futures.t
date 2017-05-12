use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Scalar::Util ();

use IO::AsyncX::SharedTimer;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new;
$loop->add(
	my $timer = new_ok('IO::AsyncX::SharedTimer', [
		resolution => '0.05',
	])
);

is(exception {
	$timer->delay_future(
		after => 0.5
	)->get;
}, undef, 'delay_future completes without raising an exception');

like(exception {
	$timer->timeout_future(
		after => 0.5
	)->get;
}, qr/\btimeout\b/i, 'timeout future does indeed raise a timeout');

isnt(
	$timer->delay_future(after => 0.5),
	$timer->delay_future(after => 0.5),
	'two delay_futures are always different'
);

my @times = map
	$timer->delay_future(
		after => 0.5
	)->transform(
		done => sub { ''.$timer->now }
	), 1..5;

is_deeply([ Future->needs_all(@times)->get ], [ ($timer->now) x 5 ], 'times are all the same');

{
	my $delay = $timer->delay_future(after => 0.2);
	my $timeout = $timer->timeout_future(after => 0.2);
	{
		my $f = Future->needs_all(
			$delay,
			$timeout
		);
		ok($delay, 'have a delay future');
		ok($timeout, 'have a timeout future');
		Scalar::Util::weaken($_) for $delay, $timeout;
		ok($delay, 'delay future is still around after weakening');
		ok($timeout, 'timeout future is still around after weakening');
		like(exception {
			$f->get;
		}, qr/timeout/i, 'have a timeout exception');
	}
	ok(!$delay, 'delay future went away');
	ok(!$timeout, 'timeout future went away');
}

done_testing;

