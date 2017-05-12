#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount;
use IO::Async::Test;

use IO::Async::OS;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new_builtin;

is_refcount( $loop, 2, '$loop has refcount 2 initially' );

testing_loop( $loop );

is_refcount( $loop, 3, '$loop has refcount 3 after adding to IO::Async::Test' );

my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot create socket pair - $!";

my $readbuffer = "";

$loop->watch_io(
   handle => $S1,
   on_read_ready => sub {
      $S1->sysread( $readbuffer, 8192, length $readbuffer ) or die "Test failed early";
   },
);

# This is just a token "does it run once?" test. A test of a test script. 
# Mmmmmm. Meta-testing.
# Coming up with a proper test that would guarantee multiple loop_once
# cycles, etc.. is difficult. TODO for later I feel.
# In any case, the wait_for function is effectively tested to death in later
# test scripts which use it. If it fails to work, they'd notice it.

$S2->syswrite( "A line\n" );

wait_for { $readbuffer =~ m/\n/ };

is( $readbuffer, "A line\n", 'Single-wait' );

$loop->unwatch_io(
   handle => $S1,
   on_read_ready => 1,
);

# Now the automatic version

$readbuffer = "";

$S2->syswrite( "Another line\n" );

wait_for_stream { $readbuffer =~ m/\n/ } $S1 => $readbuffer;

is( $readbuffer, "Another line\n", 'Automatic stream read wait' );

$readbuffer = "";

$S2->syswrite( "Some dynamic data\n" );

wait_for_stream { $readbuffer =~ m/\n/ } $S1 => sub { $readbuffer .= shift };

is( $readbuffer, "Some dynamic data\n" );

done_testing;
