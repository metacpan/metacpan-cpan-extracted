#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use EV;
use IO::Async::Loop::EV;
use IO::Async::Signal;

my $loop = IO::Async::Loop::EV->new;

my $ev_signal;

my $w = EV::signal "INT", sub { $ev_signal = "INT" };

my $ioasync_signal;

$loop->add(
   IO::Async::Signal->new(
      name => "INT",
      on_receipt => sub { $ioasync_signal = "INT" },
   )
);

kill INT => $$;

$loop->loop_once until defined $ev_signal and defined $ioasync_signal;

is( $ev_signal,      "INT", 'EV signal' );
is( $ioasync_signal, "INT", 'IO::Async signal' );

done_testing;
