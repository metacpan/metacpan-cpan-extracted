use strict;
use warnings;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use Test::Identity;

use Mojo::IOLoop;
use Future::Mojo;

my $loop = Mojo::IOLoop->new;

{
	my $future = Future::Mojo->new($loop);
	
	identical $future->loop, $loop, '$future->loop yields $loop';
	
	$loop->next_tick(sub { $future->done('result') });
	
	is_deeply [$future->get], ['result'], '$future->get on Future::Mojo';
}

# done_next_tick
{
	my $future = Future::Mojo->new($loop);
	
	identical $future->done_next_tick('deferred result'), $future, '->done_next_tick returns $future';
	ok !$future->is_ready, '$future not yet ready after ->done_next_tick';
	
	is_deeply [$future->get], ['deferred result'], '$future now ready after ->get';
}

# fail_next_tick
{
	my $future = Future::Mojo->new($loop);
	
	identical $future->fail_next_tick("deferred exception\n"), $future, '->fail_next_tick returns $future';
	ok !$future->is_ready, '$future not yet ready after ->fail_next_tick';
	
	$future->await;
	
	is_deeply [$future->failure], ["deferred exception\n"], '$future now ready after $future->await';
}

# new_timer
{
	my $future = Future::Mojo->new_timer($loop, 0.1);
	
	$future->await;
	ok $future->is_ready, '$future is ready from new_timer';
	is_deeply [$future->get], [], '$future->get returns empty list on new_timer';
}

# new_timeout
{
	my $future = Future::Mojo->new_timeout($loop, 0.1);
	
	$future->await;
	ok $future->is_ready, '$future is ready from new_timeout';
	is_deeply [$future->failure], ['Timeout'], '$future failed after new_timeout';
}

# timer cancellation
{
	my $called;
	my $future = Future::Mojo->new_timer($loop, 0.1)->on_done(sub { $called++ });
	
	$future->cancel;
	
	Future::Mojo->new_timer($loop, 0.3)->await;
	
	ok $future->is_ready, '$future has been canceled';
	ok !$called, '$future->cancel cancels a pending timer';
}

# loop recursion
{
	my $future = Future::Mojo->new_timer($loop, 0.1);
	Future::Mojo->new_timer($loop, 0.5)->on_done(sub { $future->done('safeguard') });
	
	my $errored;
	my $done = Future::Mojo->new($loop)->done_next_tick('first_result')->on_done(sub {
		eval { $future->await } or $errored = 1;
	})->get;
	
	is $done, 'first_result', 'first future completed';
	ok $errored, '$future->await in a running event loop throws an error';
}

done_testing;
