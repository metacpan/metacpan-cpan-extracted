#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use EV;
use IO::Async::Loop::EV;
use IO::Async::PID;

sub make_child
{
   defined( my $kid = fork ) or die "Cannot fork - $!";

   $kid or exec( $^X, "-e", "exit 5" ) or die "Cannot exec $^X - $!";

   return $kid;
}

my $loop = IO::Async::Loop::EV->new;

my $ev_status;

my $w = EV::child make_child, 0, sub { $ev_status = $_[0]->rstatus };

my $ioasync_status;

$loop->add(
   IO::Async::PID->new(
      pid => make_child,
      on_exit => sub { $ioasync_status = $_[1] },
   )
);

$loop->loop_once until defined $ev_status and defined $ioasync_status;

is( $ev_status,      5 << 8, 'EV child' );
is( $ioasync_status, 5 << 8, 'IO::Async process' );

done_testing;
