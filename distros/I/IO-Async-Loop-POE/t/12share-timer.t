#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use POE qw( Session Kernel );
use IO::Async::Loop::POE;
use IO::Async::Timer::Countdown;

my $loop = IO::Async::Loop::POE->new;

my $poe_timer;

POE::Session->create(
   inline_states => {
      _start => sub {
         $_[KERNEL]->delay( timer_expire => 1 );
      },
      timer_expire => sub { $poe_timer++ },
   },
);

my $ioasync_timer;

$loop->add(
   IO::Async::Timer::Countdown->new(
      delay => 1,
      on_expire => sub { $ioasync_timer++ },
   )->start
);

$loop->loop_once until defined $poe_timer and defined $ioasync_timer;

is( $poe_timer,     1, 'POE timer' );
is( $ioasync_timer, 1, 'IO::Async timer' );
