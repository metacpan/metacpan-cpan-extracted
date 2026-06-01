use v5.36;
use strict;
use warnings;

use Test::More;

for my $m (qw(Linux::Epoll Linux::FD::Event Linux::FD::Signal Linux::FD::Pid Linux::Event::Clock Linux::Event::Timer)) {
  eval "require $m; 1" or plan skip_all => "$m not available: $@";
}

my @mods = qw(
  Linux::Event
  Linux::Event::Loop
  Linux::Event::Backend
  Linux::Event::Backend::Epoll
  Linux::Event::Signal
  Linux::Event::Watcher
  Linux::Event::Wakeup
  Linux::Event::Pid
  Linux::Event::Scheduler
);

for my $m (@mods) {
  ok(eval "require $m; 1", "load $m") or diag $@;
}

done_testing;
