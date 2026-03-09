use v5.36;
use strict;
use warnings;

use Test::More;

for my $m (qw(Linux::Epoll Linux::Event::Clock Linux::Event::Timer)) {
  eval "require $m; 1" or plan skip_all => "$m not available: $@";
}

my @mods = qw(
  Linux::Event
  Linux::Event::Loop
  Linux::Event::Reactor
  Linux::Event::Reactor::Backend
  Linux::Event::Reactor::Backend::Epoll
  Linux::Event::Proactor
  Linux::Event::Proactor::Backend
  Linux::Event::Signal
  Linux::Event::Watcher
);

for my $m (@mods) {
  ok(eval "require $m; 1", "load $m") or diag $@;
}

done_testing;
