use strict;
use warnings;
use Test::More tests => 4;
use EntityModel::EventLoop::Perl;

my $event_loop = new_ok('EntityModel::EventLoop::Perl' => );
is($event_loop->defer(sub {
	pass('callback is triggered');
}), $event_loop, 'call ->defer');
pass('execution continues after ->defer');
done_testing;

