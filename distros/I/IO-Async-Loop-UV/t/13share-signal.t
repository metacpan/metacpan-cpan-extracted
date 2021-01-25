#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use UV;
use UV::Signal;
use IO::Async::Loop::UV;
use IO::Async::Signal;

my $loop = IO::Async::Loop::UV->new;

my $uv_signame;

my $uv_signal = UV::Signal->new(signal => POSIX::SIGINT);
$uv_signal->start(sub { $uv_signame = "INT" });

my $ioasync_signame;

$loop->add(
   IO::Async::Signal->new(
      name => "INT",
      on_receipt => sub { $ioasync_signame = "INT" },
   )
);

kill INT => $$;

$loop->loop_once until defined $uv_signame and defined $ioasync_signame;

is( $uv_signame,      "INT", 'UV signal' );
is( $ioasync_signame, "INT", 'IO::Async signal' );

done_testing;
