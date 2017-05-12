#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;

use IO::Async::Loop;
use IO::Async::SSL;

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

my $listen_sock = IO::Socket::INET->new(
   LocalHost => "localhost",
   LocalPort => 0,
   Listen => 1,
) or die "Cannot listen - $@";

# Mass cheating here
no warnings 'redefine';
*IO::Socket::SSL::connect_SSL = sub {
   return 1;
};

my $f = $loop->SSL_connect(
   addr => { family => "inet", ip => $listen_sock->sockhost, port => $listen_sock->sockport },
);

wait_for { $f->is_ready };

my $stream = $f->get;

my $server_sock = $listen_sock->accept;

my $read;
$stream->configure(
   on_read => sub {
      my ( $self, $readbuf ) = @_;
      $read = $$readbuf; $$readbuf = "";
      return 0;
   },
);
$loop->add( $stream );

# A micro mocking framework
{
   my @EXPECT;
   sub expect
   {
      my ( $method, $args, $result, $return ) = @_;
      push @EXPECT, [ $method, $args, $result, $return ];
   }

   *IO::Socket::SSL::sysread = sub {
      my ( $fh, undef, $len, $offset ) = @_;
      @EXPECT or
         fail( "Expected no more calls, got sysread" ), $! = Errno::EINVAL, return undef;

      my $e = shift @EXPECT;
      $e->[0] eq "sysread" or
         fail( "Expected $e->[0], got sysread" ), $! = Errno::EINVAL, return undef;

      pass( "Got sysread" );

      if( $e->[2] eq "return" ) {
         $_[1] = $e->[3];
         return length $e->[3];
      }
      elsif( $e->[2] eq "err" ) {
         $! = Errno::EAGAIN;
         $IO::Socket::SSL::SSL_ERROR = $e->[3];
         return undef;
      }
   };

   *IO::Socket::SSL::syswrite = sub {
      my ( $fh, $buff, $len ) = @_;
      @EXPECT or
         fail( "Expected no more calls, got syswrite" ), $! = Errno::EINVAL, return undef;

      my $e = shift @EXPECT;
      $e->[0] eq "syswrite" or
         fail( "Expected $e->[0], got syswrite" ), $! = Errno::EINVAL, return undef;

      pass( "Got syswrite" );

      is( $e->[1][0], $buff, 'Data for syswrite' );

      if( $e->[2] eq "return" ) {
         return $len;
      }
      elsif( $e->[2] eq "err" ) {
         $! = Errno::EAGAIN;
         $IO::Socket::SSL::SSL_ERROR = $e->[3];
         return undef;
      }
   };
}

# read-wants-read
{
   # Make serversock readready
   $server_sock->syswrite( "1" );

   expect sysread => [], return => "the data";

   wait_for { length $read };

   is( $read, "the data", 'read-wants-read reads data' );

   $read = "";
   CORE::sysread( $stream->read_handle, my $dummy, 8192 );
}

# read-wants-write
{
   # Make serversock readready
   $server_sock->syswrite( "2" );

   expect sysread => [], err => IO::Socket::SSL::SSL_WANT_WRITE;

   wait_for { $stream->want_writeready };

   pass( '$stream->want_writeready' );
   CORE::sysread( $stream->read_handle, my $dummy, 8192 );

   expect sysread => [], return => "late data";

   wait_for { length $read };

   is( $read, "late data", 'read-wants-write reads data after writeready' );

   $read = "";
}

# write-wants-write
{
   my $flushed;
   $stream->write( "out data", on_flush => sub { $flushed++ } );

   expect syswrite => [ "out data" ], return =>;

   wait_for { $flushed };

   pass( 'write-wants-write flushes data' );
}

# write-wants-read
{
   my $flushed;
   $stream->write( "late out data", on_flush => sub { $flushed++ } );

   # more cheating
   $stream->want_readready( 0 );

   expect syswrite => [ "late out data" ], err => IO::Socket::SSL::SSL_WANT_READ;

   wait_for { $stream->want_readready };

   pass( '$stream->want_readready' );

   expect sysread  => [], err => 0;
   expect syswrite => [ "late out data" ], return =>;

   $server_sock->syswrite( "4" );

   wait_for { $flushed };

   pass( 'write-wants-read flushes data after readready' );
}

done_testing;
