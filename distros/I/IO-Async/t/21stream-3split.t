#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Fatal;
use Test::Refcount;

use IO::File;
use Errno qw( EAGAIN EWOULDBLOCK );

use IO::Async::Loop;

use IO::Async::OS;

use IO::Async::Stream;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot create socket pair - $!";
my ( $S3, $S4 ) = IO::Async::OS->socketpair or die "Cannot create socket pair - $!";

# Need sockets in nonblocking mode
$_->blocking( 0 ) for $S1, $S2, $S3, $S4;

# useful test function
sub read_data
{
   my ( $s ) = @_;

   my $buffer;
   my $ret = $s->sysread( $buffer, 8192 );

   return $buffer if( defined $ret && $ret > 0 );
   die "Socket closed" if( defined $ret && $ret == 0 );
   return "" if $! == EAGAIN or $! == EWOULDBLOCK;
   die "Cannot sysread() - $!";
}

my @lines;

my $stream = IO::Async::Stream->new(
   read_handle => $S2,
   write_handle => $S3,
   on_read => sub {
      my $self = shift;
      my ( $buffref, $eof ) = @_;

      push @lines, $1 while $$buffref =~ s/^(.*\n)//;
      return 0;
   },
);

is_oneref( $stream, 'split read/write $stream has refcount 1 initially' );

undef @lines;

$loop->add( $stream );

is_refcount( $stream, 2, 'split read/write $stream has refcount 2 after adding to Loop' );

$stream->write( "message\n" );

$loop->loop_once( 0.1 );

is( read_data( $S4 ), "message\n", '$S4 receives data from split stream' );
is( read_data( $S1 ), "",          '$S1 empty from split stream' );

$S1->syswrite( "reverse\n" );

$loop->loop_once( 0.1 );

is_deeply( \@lines, [ "reverse\n" ], '@lines on response to split stream' );

is_refcount( $stream, 2, 'split read/write $stream has refcount 2 before removing from Loop' );

$loop->remove( $stream );

is_oneref( $stream, 'split read/write $stream refcount 1 finally' );

undef $stream;

my $buffer = "";
my $closed;

$stream = IO::Async::Stream->new(
   # No handle yet
   on_read => sub {
      my ( $self, $buffref, $eof ) = @_;
      $buffer .= $$buffref;
      $$buffref =  "";
      return 0;
   },
   on_closed => sub {
      my ( $self ) = @_;
      $closed = 1;
   },
);

is_oneref( $stream, 'latehandle $stream has refcount 1 initially' );

$loop->add( $stream );

is_refcount( $stream, 2, 'latehandle $stream has refcount 2 after adding to Loop' );

ok( exception { $stream->write( "some text" ) },
    '->write on stream with no IO handle fails' );

$stream->set_handle( $S1 );

is_refcount( $stream, 2, 'latehandle $stream has refcount 2 after setting a handle' );

$stream->write( "some text" );

$loop->loop_once( 0.1 );

my $buffer2;
$S2->sysread( $buffer2, 8192 );

is( $buffer2, "some text", 'stream-written text appears' );

$S2->syswrite( "more text" );

wait_for { length $buffer };

is( $buffer, "more text", 'stream-read text appears' );

$stream->close_when_empty;

is( $closed, 1, 'closed after close' );

ok( !defined $stream->loop, 'Stream no longer member of Loop' );

is_oneref( $stream, 'latehandle $stream refcount 1 finally' );

# Now try re-opening the stream with a new handle, and check it continues to
# work

$loop->add( $stream );

$stream->set_handle( $S3 );

$stream->write( "more text" );

$loop->loop_once( 0.1 );

undef $buffer2;
$S4->sysread( $buffer2, 8192 );

is( $buffer2, "more text", 'stream-written text appears after reopen' );

$loop->remove( $stream );

undef $stream;

( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot socketpair - $!";

$stream = IO::Async::Stream->new(
   handle => $S1,
   on_read => sub { },
);

$stream->write( "hello" );

$loop->add( $stream );

is_refcount( $stream, 2, '$stream has two references' );
undef $stream; # Only ref is now in the Loop

$S2->close;

# $S1 should now be both read- and write-ready.
ok( !exception { $loop->loop_once }, 'read+write-ready closed Stream doesn\'t die' );

undef $stream;

binmode STDIN; # Avoid harmless warning in case -CS is in effect
$stream = IO::Async::Stream->new_for_stdio;
is( $stream->read_handle,  \*STDIN,  'Stream->new_for_stdio->read_handle is STDIN' );
is( $stream->write_handle, \*STDOUT, 'Stream->new_for_stdio->write_handle is STDOUT' );

done_testing;
