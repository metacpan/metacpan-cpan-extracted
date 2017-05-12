#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Refcount;

use Errno qw( EAGAIN EWOULDBLOCK ECONNRESET );

use IO::Async::Loop;

use IO::Async::OS;

use IO::Async::Stream;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

sub mkhandles
{
   my ( $rd, $wr ) = IO::Async::OS->pipepair or die "Cannot pipe() - $!";
   # Need handles in nonblocking mode
   $rd->blocking( 0 );
   $wr->blocking( 0 );

   return ( $rd, $wr );
}

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

{
   my ( $rd, $wr ) = mkhandles;

   my $empty;

   my $stream = IO::Async::Stream->new(
      write_handle => $wr,
      on_outgoing_empty => sub { $empty = 1 },
   );

   ok( defined $stream, 'writing $stream defined' );
   isa_ok( $stream, "IO::Async::Stream", 'writing $stream isa IO::Async::Stream' );

   is_oneref( $stream, 'writing $stream has refcount 1 initially' );

   $loop->add( $stream );

   is_refcount( $stream, 2, 'writing $stream has refcount 2 after adding to Loop' );

   ok( !$stream->want_writeready, 'want_writeready before write' );
   $stream->write( "message\n" );

   ok( $stream->want_writeready, 'want_writeready after write' );

   wait_for { $empty };

   ok( !$stream->want_writeready, 'want_writeready after wait' );
   is( $empty, 1, '$empty after writing buffer' );

   is( read_data( $rd ), "message\n", 'data after writing buffer' );

   my $written = 0;
   my $flushed;

   my $f = $stream->write( "hello again\n",
      on_write => sub {
         is( $_[0], $stream, 'on_write $_[0] is $stream' );
         $written += $_[1];
      },
      on_flush => sub {
         is( $_[0], $stream, 'on_flush $_[0] is $stream' );
         $flushed++
      },
   );

   ok( !$f->is_ready, '->write future not yet ready' );

   wait_for { $flushed };

   ok( $f->is_ready, '->write future is ready after flush' );
   is( $written, 12, 'on_write given total write length after flush' );
   is( read_data( $rd ), "hello again\n", 'flushed data does get flushed' );

   $flushed = 0;
   $stream->write( "", on_flush => sub { $flushed++ } );
   wait_for { $flushed };

   ok( 1, "write empty data with on_flush" );

   $stream->configure( autoflush => 1 );
   $stream->write( "immediate\n" );

   ok( !$stream->want_writeready, 'not want_writeready after autoflush write' );
   is( read_data( $rd ), "immediate\n", 'data after autoflush write' );

   $stream->configure( autoflush => 0 );
   $stream->write( "partial " );
   $stream->configure( autoflush => 1 );
   $stream->write( "data\n" );

   ok( !$stream->want_writeready, 'not want_writeready after split autoflush write' );
   is( read_data( $rd ), "partial data\n", 'data after split autoflush write' );

   is_refcount( $stream, 2, 'writing $stream has refcount 2 before removing from Loop' );

   $loop->remove( $stream );

   is_oneref( $stream, 'writing $stream refcount 1 finally' );
}

# Abstract writing with writer function
{
   my ( $rd, $wr ) = mkhandles;
   my $buffer;

   my $stream = IO::Async::Stream->new(
      write_handle => $wr,
      writer => sub {
         my $self = shift;
         $buffer .= substr( $_[1], 0, $_[2], "" );
         return $_[2];
      },
   );

   $loop->add( $stream );

   my $flushed;
   $stream->write( "Some data for abstract buffer\n", on_flush => sub { $flushed++ } );

   wait_for { $flushed };

   is( $buffer, "Some data for abstract buffer\n", '$buffer after ->write to stream with abstract writer' );

   $loop->remove( $stream );
}

# ->want_writeready_for_read
{
   my ( $rd, $wr ) = mkhandles;

   my $reader_called;
   my $stream = IO::Async::Stream->new(
      handle => $wr,
      on_read => sub { return 0; }, # ignore reading
      reader => sub { $reader_called++; $! = EAGAIN; return undef },
   );

   $loop->add( $stream );

   $loop->loop_once( 0.1 ); # haaaaack

   ok( !$reader_called, 'reader not yet called before ->want_writeready_for_read' );

   $stream->want_writeready_for_read( 1 );

   wait_for { $reader_called };

   ok( $reader_called, 'reader now invoked with ->want_writeready_for_read' );

   $loop->remove( $stream );
}

# on_writeable_{start,stop}
{
   my ( $rd, $wr ) = mkhandles;
   my $buffer;

   my $writeable;
   my $unwriteable;
   my $emulate_writeable = 0;
   my $stream = IO::Async::Stream->new(
      write_handle => $wr,
      writer => sub {
         my $self = shift;
         $! = EAGAIN, return undef unless $emulate_writeable;

         $buffer .= substr( $_[1], 0, $_[2], "" );
         return $_[2];
      },
      on_writeable_start => sub { $writeable++ },
      on_writeable_stop  => sub { $unwriteable++ },
   );

   $loop->add( $stream );

   $stream->write( "Something" );

   wait_for { $unwriteable };

   $emulate_writeable = 1;

   wait_for { $writeable };

   is( $buffer, "Something", '$buffer after emulated EAGAIN' );

   $loop->remove( $stream );
}

{
   my ( $rd, $wr ) = mkhandles;

   my $stream = IO::Async::Stream->new(
      write_handle => $wr,
      write_len => 2,
   );

   $loop->add( $stream );

   $stream->write( "partial" );

   $loop->loop_once( 0.1 );

   is( read_data( $rd ), "pa", 'data after writing buffer with write_len=2 without write_all');

   $loop->loop_once( 0.1 ) for 1 .. 3;

   is( read_data( $rd ), "rtial", 'data finally after writing buffer with write_len=2 without write_all' );

   $stream->configure( write_all => 1 );

   $stream->write( "partial" );

   $loop->loop_once( 0.1 );

   is( read_data( $rd ), "partial", 'data after writing buffer with write_len=2 with write_all');

   $loop->remove( $stream );
}

# EOF
SKIP: {
   skip "This loop cannot detect hangup condition", 5 unless $loop->_CAN_ON_HANGUP;

   my ( $rd, $wr ) = mkhandles;

   local $SIG{PIPE} = "IGNORE";

   my $eof = 0;

   my $stream = IO::Async::Stream->new( write_handle => $wr,
      on_write_eof => sub { $eof++ },
   );

   $loop->add( $stream );

   my $write_future = $stream->write( "Junk" );

   $rd->close;

   ok( !$stream->is_write_eof, '$stream->is_write_eof before wait' );
   is( $eof, 0, 'EOF indication before wait' );

   wait_for { $eof };

   ok( $stream->is_write_eof, '$stream->is_write_eof after wait' );
   is( $eof, 1, 'EOF indication after wait' );

   ok( !defined $stream->loop, 'EOF stream no longer member of Loop' );

   ok( $write_future->is_ready,'write future ready after stream closed' );
   ok( $write_future->is_failed,'write future failed after stream closed' );
}

# Close
{
   my ( $rd, $wr ) = mkhandles;

   my $closed = 0;
   my $loop_during_closed;

   my $stream = IO::Async::Stream->new( write_handle => $wr,
      on_closed => sub {
         my ( $self ) = @_;
         $closed = 1;
         $loop_during_closed = $self->loop;
      },
   );

   is_oneref( $stream, 'closing $stream has refcount 1 initially' );

   $stream->write( "hello" );

   $loop->add( $stream );

   is_refcount( $stream, 2, 'closing $stream has refcount 2 after adding to Loop' );

   is( $closed, 0, 'closed before close' );

   $stream->close_when_empty;

   is( $closed, 0, 'closed after close' );

   wait_for { $closed };

   is( $closed, 1, 'closed after wait' );
   is( $loop_during_closed, $loop, 'loop during closed' );

   ok( !defined $stream->loop, 'Stream no longer member of Loop' );

   is_oneref( $stream, 'closing $stream refcount 1 finally' );
}

# ->write( Future )
{
   my ( $rd, $wr ) = mkhandles;
   my $stream = IO::Async::Stream->new(
      write_handle => $wr,
   );
   $loop->add( $stream );

   my $written = 0;
   my $flushed;
   $stream->write(
      my $future = $loop->new_future,
      on_write => sub { $written += $_[1] },
      on_flush => sub { $flushed++ },
   );

   $loop->loop_once( 0.1 );
   is( read_data( $rd ), "", 'stream idle before Future completes' );

   $future->done( "some data to write" );

   wait_for { $flushed };

   is( $written, 18, 'stream written by Future completion invokes on_write' );

   is( read_data( $rd ), "some data to write", 'stream written by Future completion' );

   $loop->remove( $stream );
}

# ->write( CODE )
{
   my ( $rd, $wr ) = mkhandles;
   my $stream = IO::Async::Stream->new(
      write_handle => $wr,
   );
   $loop->add( $stream );

   my $done;
   my $written = 0;
   my $flushed;

   $stream->write(
      sub {
         is( $_[0], $stream, 'Writersub $_[0] is $stream' );
         return $done++ ? undef : "a lazy message\n";
      },
      on_write => sub { $written += $_[1] },
      on_flush => sub { $flushed++ },
   );

   $flushed = 0;
   wait_for { $flushed };

   is( $written, 15, 'stream written by generator CODE invokes on_write' );

   is( read_data( $rd ), "a lazy message\n", 'lazy data was written' );

   my @chunks = ( "some ", "message chunks ", "here\n" );

   $stream->write(
      sub {
         return shift @chunks;
      },
      on_flush => sub { $flushed++ },
   );

   $flushed = 0;
   wait_for { $flushed };

   is( read_data( $rd ), "some message chunks here\n", 'multiple lazy data was written' );

   $loop->remove( $stream );
}

# ->write mixed returns
{
   my ( $rd, $wr ) = mkhandles;
   my $stream = IO::Async::Stream->new(
      write_handle => $wr,
   );
   $loop->add( $stream );

   my $flushed;
   $stream->write( my $future = $loop->new_future, on_flush => sub { $flushed++ } );

   my $once = 0;
   $future->done( sub {
      return $once++ ? undef : ( $future = $loop->new_future );
   });

   wait_for { $once };

   $future->done( "Eventual string" );

   wait_for { $flushed };

   is( read_data( $rd ), "Eventual string", 'multiple lazy data was written' );

   $loop->remove( $stream );
}

{
   my ( $rd, $wr ) = mkhandles;

   my $stream = IO::Async::Stream->new;

   my $flushed;

   $stream->write( "Prequeued data", on_flush => sub { $flushed++ } );

   $stream->configure( write_handle => $wr );

   $loop->add( $stream );

   wait_for { $flushed };

   ok( 1, 'prequeued data gets flushed' );

   is( read_data( $rd ), "Prequeued data", 'prequeued data gets written' );

   $loop->remove( $stream );
}

# Errors
{
   my ( $rd, $wr ) = mkhandles;

   no warnings 'redefine';
   local *IO::Handle::syswrite = sub {
      $! = ECONNRESET;
      return undef;
   };

   my $write_errno;

   my $stream = IO::Async::Stream->new(
      write_handle => $wr,
      on_write_error  => sub { ( undef, $write_errno ) = @_ },
   );

   $loop->add( $stream );

   my $write_future = $stream->write( "hello" );

   wait_for { defined $write_errno };

   cmp_ok( $write_errno, "==", ECONNRESET, 'errno after failed write' );

   ok( $write_future->is_ready,'write future ready after failed write' );
   ok( $write_future->is_failed,'write future failed after failed write' );

   $loop->remove( $stream );
}

{
   my $stream = IO::Async::Stream->new_for_stdout;
   is( $stream->write_handle, \*STDOUT, 'Stream->new_for_stdout->write_handle is STDOUT' );
}

done_testing;
