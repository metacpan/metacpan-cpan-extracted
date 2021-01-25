#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use UV;
use UV::Timer;
use IO::Async::Loop::UV;
use IO::Async::Timer::Countdown;

my $loop = IO::Async::Loop::UV->new;

my $uv_count;

my $uv_timer = UV::Timer->new;
$uv_timer->start( 1000, 0, sub { $uv_count++ } );

my $ioasync_count;

$loop->add(
   IO::Async::Timer::Countdown->new(
      delay => 1,
      on_expire => sub { $ioasync_count++ },
   )->start
);

$loop->loop_once until defined $uv_count and defined $ioasync_count;

is( $uv_count,      1, 'UV timer' );
is( $ioasync_count, 1, 'IO::Async timer' );

done_testing;
