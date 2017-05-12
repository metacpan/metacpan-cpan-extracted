#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Poll;

use IO::Async::OS;

use IO::Async::Loop::Poll;

my $poll = IO::Poll->new;
my $loop = IO::Async::Loop::Poll->new( poll => $poll );

my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot create socket pair - $!";

# Need sockets in nonblocking mode
$S1->blocking( 0 );
$S2->blocking( 0 );

# Empty

is_deeply( [ $poll->handles ], [], '$poll->handles empty initially' );

# watch_io

my $readready = 0;
$loop->watch_io(
   handle => $S1,
   on_read_ready  => sub { $readready = 1 },
);

is_deeply( [ $poll->handles ], [ $S1 ], '$poll->handles after watch_io read_ready' );

$S2->syswrite( "data\n" );

# We should still wait a little while even thought we expect to be ready
# immediately, because talking to ourself with 0 poll timeout is a race
# condition - we can still race with the kernel.

$poll->poll( 0.1 );

is( $readready, 0, '$readready before post_poll' );
$loop->post_poll;
is( $readready, 1, '$readready after post_poll' );

# Ready $S1 to clear the data
$S1->getline; # ignore return

$loop->unwatch_io(
   handle => $S1,
   on_read_ready => 1,
);

is_deeply( [ $poll->handles ], [], '$poll->handles empty after unwatch_io read_ready' );

my $writeready = 0;
$loop->watch_io(
   handle => $S1,
   on_write_ready => sub { $writeready = 1 },
);

is_deeply( [ $poll->handles ], [ $S1 ], '$poll->handles after watch_io write_ready' );

$poll->poll( 0.1 );

is( $writeready, 0, '$writeready before post_poll' );
$loop->post_poll;
is( $writeready, 1, '$writeready after post_poll' );

$loop->unwatch_io(
   handle => $S1,
   on_write_ready => 1,
);

is_deeply( [ $poll->handles ], [], '$poll->handles empty after unwatch_io write_ready' );

# Removal is clean (tests for workaround to bug in IO::Poll version 0.05)

my ( $P1, $P2 ) = IO::Async::OS->pipepair or die "Cannot pipepair - $!";

# Just to make the loop non-empty
$loop->watch_io( handle => $P2, on_read_ready => sub {} );

$loop->watch_io( handle => \*STDOUT, on_write_ready => sub {} );

is( scalar $poll->handles, 2, '$poll->handles before removal in clean removal test' );

$loop->unwatch_io( handle => \*STDOUT, on_write_ready => 1 );

is( scalar $poll->handles, 1, '$poll->handles after removal in clean removal test' );

done_testing;
