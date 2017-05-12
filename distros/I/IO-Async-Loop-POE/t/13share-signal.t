#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use POE qw( Session Kernel );
use IO::Async::Loop::POE;
use IO::Async::Signal;

my $loop = IO::Async::Loop::POE->new;

my $poe_signal;

POE::Session->create(
   inline_states => {
      _start => sub {
         $_[KERNEL]->sig( INT => 'sigint' );
      },
      sigint => sub { $poe_signal = $_[ARG0]; $_[KERNEL]->sig_handled },
   },
);

my $ioasync_signal;

$loop->add(
   IO::Async::Signal->new(
      name => "INT",
      on_receipt => sub { $ioasync_signal = "INT" },
   )
);

kill INT => $$;

$loop->loop_once until defined $poe_signal and defined $ioasync_signal;

is( $poe_signal,     "INT", 'POE signal' );
is( $ioasync_signal, "INT", 'IO::Async signal' );
