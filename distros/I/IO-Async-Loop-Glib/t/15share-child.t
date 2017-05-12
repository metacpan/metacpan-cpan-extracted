#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Glib;
use IO::Async::Loop::Glib;
use IO::Async::PID;

sub make_child
{
   defined( my $kid = fork ) or die "Cannot fork - $!";

   $kid or exec( $^X, "-e", "exit 5" ) or die "Cannot exec $^X - $!";

   return $kid;
}

my $loop = IO::Async::Loop::Glib->new;

my $glib_status;

Glib::Child->watch_add( make_child, sub { $glib_status = $_[1] } );

my $ioasync_status;

$loop->add(
   IO::Async::PID->new(
      pid => make_child,
      on_exit => sub { $ioasync_status = $_[1] },
   )
);

$loop->loop_once until defined $glib_status and defined $ioasync_status;

is( $glib_status, 5 << 8, 'Glib child' );
is( $ioasync_status,  5 << 8, 'IO::Async child' );

done_testing;
