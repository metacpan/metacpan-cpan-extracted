#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use AnyEvent;
use IO::Async::Loop::AnyEvent;
use IO::Async::Timer::Countdown;

my $loop = IO::Async::Loop::AnyEvent->new;

my $anyevent_timer;

my $w = AnyEvent->timer(
   after => 1,
   cb    => sub { $anyevent_timer++ },
);

my $ioasync_timer;

$loop->add(
   IO::Async::Timer::Countdown->new(
      delay => 1,
      on_expire => sub { $ioasync_timer++ },
   )->start
);

$loop->loop_once until defined $anyevent_timer and defined $ioasync_timer;

is( $anyevent_timer, 1, 'AnyEvent timer' );
is( $ioasync_timer,  1, 'IO::Async timer' );
