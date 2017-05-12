#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use AnyEvent;
use IO::Async::Loop::AnyEvent;
use IO::Async::Signal;

my $loop = IO::Async::Loop::AnyEvent->new;

my $anyevent_signal;

my $w = AnyEvent->signal(
   signal => "INT",
   cb     => sub { $anyevent_signal = "INT" },
);

my $ioasync_signal;

$loop->add(
   IO::Async::Signal->new(
      name => "INT",
      on_receipt => sub { $ioasync_signal = "INT" },
   )
);

kill INT => $$;

$loop->loop_once until defined $anyevent_signal and defined $ioasync_signal;

is( $anyevent_signal, "INT", 'AnyEvent signal' );
is( $ioasync_signal,  "INT", 'IO::Async signal' );
