#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use EV;
use IO::Async::Loop::EV;
use IO::Async::Timer::Countdown;

my $loop = IO::Async::Loop::EV->new;

my $ev_timer;

my $w = EV::timer 1, 0, sub { $ev_timer++ };

my $ioasync_timer;

$loop->add(
   IO::Async::Timer::Countdown->new(
      delay => 1,
      on_expire => sub { $ioasync_timer++ },
   )->start
);

$loop->loop_once until defined $ev_timer and defined $ioasync_timer;

is( $ev_timer,      1, 'EV timer' );
is( $ioasync_timer, 1, 'IO::Async timer' );
