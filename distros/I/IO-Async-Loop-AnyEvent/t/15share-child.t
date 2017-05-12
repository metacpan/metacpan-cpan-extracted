#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use AnyEvent;
use IO::Async::Loop::AnyEvent;
use IO::Async::PID;

sub make_child
{
   defined( my $kid = fork ) or die "Cannot fork - $!";

   $kid or exec( $^X, "-e", "exit 5" ) or die "Cannot exec $^X - $!";

   return $kid;
}

my $loop = IO::Async::Loop::AnyEvent->new;

my $anyevent_status;

my $w = AnyEvent->child(
   pid => make_child,
   cb  => sub { $anyevent_status = $_[1] },
);

my $ioasync_status;

$loop->add(
   IO::Async::PID->new(
      pid => make_child,
      on_exit => sub { $ioasync_status = $_[1] },
   )
);

$loop->loop_once until defined $anyevent_status and defined $ioasync_status;

is( $anyevent_status, 5 << 8, 'AnyEvent child' );
is( $ioasync_status,  5 << 8, 'IO::Async child' );
