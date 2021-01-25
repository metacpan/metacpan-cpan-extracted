#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use UV;
use UV::Process;
use IO::Async::Loop::UV;
use IO::Async::PID;

sub make_child
{
   defined( my $kid = fork ) or die "Cannot fork - $!";

   $kid or exec( $^X, "-e", "exit 5" ) or die "Cannot exec $^X - $!";

   return $kid;
}

my $loop = IO::Async::Loop::UV->new;

my $uv_exitcode;

# libuv does not have child PID watch ability, so we'll have to ask it to do
# the full fork/exec
my $uv_process = UV::Process->spawn(
   file => $^X,
   args => [ "-e", "exit 5" ],
   on_exit => sub {
      (undef, $uv_exitcode, undef) = @_;
   }
);

my $ioasync_status;

$loop->add(
   IO::Async::PID->new(
      pid => make_child,
      on_exit => sub { $ioasync_status = $_[1] },
   )
);

$loop->loop_once until defined $uv_exitcode and defined $ioasync_status;

is( $uv_exitcode,    5,      'UV child' );
is( $ioasync_status, 5 << 8, 'IO::Async process' );

done_testing;
