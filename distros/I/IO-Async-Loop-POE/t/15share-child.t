#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use POE qw( Session Kernel );
use IO::Async::Loop::POE;
use IO::Async::PID;

sub make_child
{
   defined( my $kid = fork ) or die "Cannot fork - $!";

   $kid or exec( $^X, "-e", "exit 5" ) or die "Cannot exec $^X - $!";

   return $kid;
}

my $loop = IO::Async::Loop::POE->new;

my $poe_status;

POE::Session->create(
   inline_states => {
      _start => sub {
         $_[KERNEL]->sig_child( make_child, 'child_exit' );
      },
      child_exit => sub { $poe_status = $_[ARG2] }
   },
);

my $ioasync_status;

$loop->add(
   IO::Async::PID->new(
      pid => make_child,
      on_exit => sub { $ioasync_status = $_[1] },
   )
);

$loop->loop_once until defined $poe_status and defined $ioasync_status;

is( $poe_status,     5 << 8, 'POE child' );
is( $ioasync_status, 5 << 8, 'IO::Async child' );
