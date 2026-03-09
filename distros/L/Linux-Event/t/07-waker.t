use v5.36;
use strict;
use warnings;

use Test::More;

for my $m (qw(Linux::Epoll Linux::Event::Clock Linux::Event::Timer Linux::FD::Event)) {
  eval "require $m; 1" or plan skip_all => "$m not available: $@";
}

use Linux::Event::Loop;

my $loop  = Linux::Event::Loop->new( model => 'reactor', backend => 'epoll' );
my $waker = $loop->waker;

ok($waker && $waker->can('fh'),     'waker() returns an object with fh');
ok($waker && $waker->can('signal'), 'waker() returns an object with signal');
ok($waker && $waker->can('drain'),  'waker() returns an object with drain');

my @seen;

$loop->watch(
  $waker->fh,
  read => sub ($loop, $fh, $watcher) {
    push @seen, $waker->drain;
  },
);

$waker->signal(3);

my $t0 = time;
while (!@seen) {
  $loop->run_once(0.05);
  last if time - $t0 > 1;
}

ok(@seen, 'waker readability dispatches');
is($seen[0], 3, 'drain returns coalesced count');

# drain is idempotent when nothing is pending.
is($waker->drain, 0, 'drain returns 0 when nothing pending');

done_testing;
