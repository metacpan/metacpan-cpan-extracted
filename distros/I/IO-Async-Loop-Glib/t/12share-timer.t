#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Glib;
use IO::Async::Loop::Glib;
use IO::Async::Timer::Countdown;

my $loop = IO::Async::Loop::Glib->new;

my $glib_timer;

Glib::Timeout->add( 1000, sub { $glib_timer++ } );

my $ioasync_timer;

$loop->add(
   IO::Async::Timer::Countdown->new(
      delay => 1,
      on_expire => sub { $ioasync_timer++ },
   )->start
);

$loop->loop_once until defined $glib_timer and defined $ioasync_timer;

is( $glib_timer,    1, 'Glib timer' );
is( $ioasync_timer, 1, 'IO::Async timer' );

done_testing;
