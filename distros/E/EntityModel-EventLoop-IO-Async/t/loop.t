use strict;
use warnings;

use Test::More tests => 19;
use EntityModel::EventLoop::IO::Async;
use IO::Async::Loop;
use Test::Fatal;

my $event_loop = new_ok('EntityModel::EventLoop::IO::Async' =>);
is($event_loop->loop, undef, 'start off with no IO::Async::Loop');
isa_ok($event_loop->event_loop, 'IO::Async::Loop', 'auto-assign IO::Async::Loop as required');

ok($event_loop->loop(undef), 'clear event loop');
is($event_loop->loop, undef, 'IO::Async::Loop is cleared correctly');

my %seen;
my %method_map = (
	'sleep' => sub { my ($el, $k) = @_; $el->sleep(0.05 => sub { $seen{$k}++; $el->loop->loop_stop }) },
	'defer' => sub { my ($el, $k) = @_; $el->defer(sub { $seen{$k}++; $el->loop->loop_stop }) },
);

foreach my $method (keys %method_map) {
	my $code = $method_map{$method};
	is($seen{$method} || 0, 0, 'event not seen yet');
	is(exception { $code->($event_loop, $method) }, undef, 'code runs without raising an exception');
	isa_ok($event_loop->loop, 'IO::Async::Loop', 'auto-assign IO::Async::Loop as required');
	# Just in case
	ok(my $id = $event_loop->loop->enqueue_timer(delay => 15, code => sub { fail('Had to bail out'); $event_loop->loop->loop_stop }), 'set an emergency bailout timer');;

	$event_loop->loop->loop_forever;
	$event_loop->loop->cancel_timer($id);

	is(join(',', keys %seen), $method, 'only the one method was triggered');
	delete $seen{$method};
	ok($event_loop->loop(undef), 'clear event loop');
	is($event_loop->loop, undef, 'IO::Async::Loop is cleared correctly');
}

