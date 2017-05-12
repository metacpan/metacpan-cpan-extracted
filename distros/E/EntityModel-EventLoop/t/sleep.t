use strict;
use warnings;
use Test::More tests => 4;
use EntityModel::EventLoop::Perl;

my $event_loop = new_ok('EntityModel::EventLoop::Perl' => );
is($event_loop->sleep(0.05 => sub {
	pass('callback is triggered');
}), $event_loop, 'call ->sleep');
pass('execution continues after ->sleep');
done_testing;

