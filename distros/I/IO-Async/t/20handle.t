#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Fatal;
use Test::Identity;
use Test::Refcount;

use IO::Async::Loop;

use IO::Async::Handle;

use IO::Async::OS;

use Socket qw( AF_INET SOCK_STREAM SOCK_DGRAM SO_TYPE unpack_sockaddr_in );

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

sub mkhandles
{
   my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot create socket pair - $!";

   # Need sockets in nonblocking mode
   $S1->blocking( 0 );
   $S2->blocking( 0 );

   return ( $S1, $S2 );
}

ok( exception { IO::Async::Handle->new( handle => "Hello" ) }, 'Not a filehandle' );

# Read readiness
{
   my ( $S1, $S2 ) = mkhandles;
   my $fd1 = $S1->fileno;

   my $readready = 0;
   my @rrargs;

   my $handle = IO::Async::Handle->new(
      read_handle => $S1,
      on_read_ready  => sub { @rrargs = @_; $readready = 1 },
   );

   ok( defined $handle, '$handle defined' );
   isa_ok( $handle, "IO::Async::Handle", '$handle isa IO::Async::Handle' );

   is( $handle->notifier_name, "r=$fd1", '$handle->notifier_name for read_handle' );

   is_oneref( $handle, '$handle has refcount 1 initially' );

   is( $handle->read_handle,  $S1, '->read_handle returns S1' );
   is( $handle->read_fileno,  $S1->fileno, '->read_fileno returns fileno(S1)' );

   is( $handle->write_handle, undef, '->write_handle returns undef' );

   ok( $handle->want_readready, 'want_readready true' );

   $loop->add( $handle );

   is_refcount( $handle, 2, '$handle has refcount 2 after adding to Loop' );

   $loop->loop_once( 0.1 ); # nothing happens

   is( $readready,  0, '$readready while idle' );

   $S2->syswrite( "data\n" );

   wait_for { $readready };

   is( $readready,  1, '$readready while readable' );
   is_deeply( \@rrargs, [ $handle ], 'on_read_ready args while readable' );

   $S1->getline; # ignore return

   $readready = 0;
   my $new_readready = 0;

   $handle->configure( on_read_ready => sub { $new_readready = 1 } );

   $loop->loop_once( 0.1 ); # nothing happens

   is( $readready,     0, '$readready while idle after on_read_ready replace' );
   is( $new_readready, 0, '$new_readready while idle after on_read_ready replace' );

   $S2->syswrite( "data\n" );

   wait_for { $new_readready };

   is( $readready,     0, '$readready while readable after on_read_ready replace' );
   is( $new_readready, 1, '$new_readready while readable after on_read_ready replace' );

   $S1->getline; # ignore return

   ok( exception { $handle->want_writeready( 1 ); },
       'setting want_writeready with write_handle == undef dies' );
   ok( !$handle->want_writeready, 'wantwriteready write_handle == undef false' );

   undef @rrargs;

   is_refcount( $handle, 2, '$handle has refcount 2 before removing from Loop' );

   $loop->remove( $handle );

   is_oneref( $handle, '$handle has refcount 1 finally' );
}

# Write readiness
{
   my ( $S1, $S2 ) = mkhandles;
   my $fd1 = $S1->fileno;

   my $writeready = 0;
   my @wrargs;

   my $handle = IO::Async::Handle->new(
      write_handle => $S1,
      on_write_ready => sub { @wrargs = @_; $writeready = 1 },
   );

   ok( defined $handle, '$handle defined' );
   isa_ok( $handle, "IO::Async::Handle", '$handle isa IO::Async::Handle' );

   is( $handle->notifier_name, "w=$fd1", '$handle->notifier_name for write_handle' );

   is_oneref( $handle, '$handle has refcount 1 initially' );

   is( $handle->write_handle, $S1, '->write_handle returns S1' );
   is( $handle->write_fileno, $S1->fileno, '->write_fileno returns fileno(S1)' );

   is( $handle->read_handle, undef, '->read_handle returns undef' );

   ok( !$handle->want_writeready, 'want_writeready false' );

   $loop->add( $handle );

   is_refcount( $handle, 2, '$handle has refcount 2 after adding to Loop' );

   $loop->loop_once( 0.1 ); # nothing happens

   is( $writeready, 0, '$writeready while idle' );

   $handle->want_writeready( 1 );

   wait_for { $writeready };

   is( $writeready, 1, '$writeready while writeable' );
   is_deeply( \@wrargs, [ $handle ], 'on_write_ready args while writeable' );

   $writeready = 0;
   my $new_writeready = 0;

   $handle->configure( on_write_ready => sub { $new_writeready = 1 } );

   wait_for { $new_writeready };

   is( $writeready,     0, '$writeready while writeable after on_write_ready replace' );
   is( $new_writeready, 1, '$new_writeready while writeable after on_write_ready replace' );

   undef @wrargs;

   is_refcount( $handle, 2, '$handle has refcount 2 before removing from Loop' );

   $loop->remove( $handle );

   is_oneref( $handle, '$handle has refcount 1 finally' );
}

# Combined handle
{
   my ( $S1, $S2 ) = mkhandles;
   my $fd1 = $S1->fileno;

   my $handle = IO::Async::Handle->new(
      handle => $S1,
      on_read_ready  => sub {},
      on_write_ready => sub {},
   );

   is( $handle->read_handle,  $S1, '->read_handle returns S1' );
   is( $handle->write_handle, $S1, '->write_handle returns S1' );

   is( $handle->notifier_name, "rw=$fd1", '$handle->notifier_name for handle' );
}

# Subclass
my $sub_readready = 0;
my $sub_writeready = 0;

{
   my ( $S1, $S2 ) = mkhandles;

   my $handle = TestHandle->new(
      handle => $S1,
   );

   ok( defined $handle, 'subclass $handle defined' );
   isa_ok( $handle, "IO::Async::Handle", 'subclass $handle isa IO::Async::Handle' );

   is_oneref( $handle, 'subclass $handle has refcount 1 initially' );

   is( $handle->read_handle,  $S1, 'subclass ->read_handle returns S1' );
   is( $handle->write_handle, $S1, 'subclass ->write_handle returns S1' );

   $loop->add( $handle );

   is_refcount( $handle, 2, 'subclass $handle has refcount 2 after adding to Loop' );

   $S2->syswrite( "data\n" );

   wait_for { $sub_readready };

   is( $sub_readready,  1, '$sub_readready while readable' );
   is( $sub_writeready, 0, '$sub_writeready while readable' );

   $S1->getline; # ignore return
   $sub_readready = 0;

   $handle->want_writeready( 1 );

   wait_for { $sub_writeready };

   is( $sub_readready,  0, '$sub_readready while writeable' );
   is( $sub_writeready, 1, '$sub_writeready while writeable' );

   $loop->remove( $handle );
}

# Close
{
   my ( $S1, $S2 ) = mkhandles;

   my $closed = 0;

   my $handle = IO::Async::Handle->new(
      read_handle => $S1,
      want_writeready => 0,
      on_read_ready => sub {},
      on_closed => sub { $closed = 1 },
   );

   $loop->add( $handle );

   my $close_future = $handle->new_close_future;

   my $closed_by_future;
   $close_future->on_done( sub { $closed_by_future++ } );

   $handle->close;

   is( $closed, 1, '$closed after ->close' );

   ok( $close_future->is_ready, '$close_future is now ready' );
   is( $closed_by_future, 1, '$closed_by_future after ->close' );

   # removed itself
}

# Close read/write
{
   my ( $Srd1, $Srd2 ) = mkhandles;
   my ( $Swr1, $Swr2 ) = mkhandles;

   local $SIG{PIPE} = "IGNORE";

   my $readready  = 0;
   my $writeready = 0;

   my $closed = 0;

   my $handle = IO::Async::Handle->new(
      read_handle  => $Srd1,
      write_handle => $Swr1,
      on_read_ready  => sub { $readready++ },
      on_write_ready => sub { $writeready++ },
      on_closed      => sub { $closed++ },
      want_writeready => 1,
   );

   $loop->add( $handle );

   $handle->close_read;

   wait_for { $writeready };
   is( $writeready, 1, '$writeready after ->close_read' );

   $handle->write_handle->syswrite( "Still works\n" );
   is( $Swr2->getline, "Still works\n", 'write handle still works' );

   is( $closed, 0, 'not $closed after ->close_read' );

   is( $handle->loop, $loop, 'Handle still member of Loop after ->close_read' );

   ( $Srd1, $Srd2 ) = mkhandles;

   $handle->configure( read_handle => $Srd1 );

   $handle->close_write;

   $Srd2->syswrite( "Also works\n" );

   wait_for { $readready };
   is( $readready, 1, '$readready after ->close_write' );

   is( $handle->read_handle->getline, "Also works\n", 'read handle still works' );
   is( $Swr2->getline, undef, 'sysread from EOF write handle' );

   is( $handle->loop, $loop, 'Handle still member of Loop after ->close_write' );

   is( $closed, 0, 'not $closed after ->close_read' );

   $handle->close_read;

   is( $closed, 1, '$closed after ->close_read + ->close_write' );

   is( $handle->loop, undef, '$handle no longer member of Loop' );
}

# Late-binding of handle
{
   my $readready;
   my $writeready;

   my $handle = IO::Async::Handle->new(
      want_writeready => 0,
      on_read_ready  => sub { $readready  = 1 },
      on_write_ready => sub { $writeready = 1 },
   );

   ok( defined $handle, '$handle defined' );

   ok( !defined $handle->read_handle,  '->read_handle not defined' );
   ok( !defined $handle->write_handle, '->write_handle not defined' );

   is_oneref( $handle, '$handle latebound has refcount 1 initially' );

   is( $handle->notifier_name, "no", '$handle->notifier_name for late bind before handles' );

   $loop->add( $handle );

   is_refcount( $handle, 2, '$handle latebound has refcount 2 after $loop->add' );

   my ( $S1, $S2 ) = mkhandles;
   my $fd1 = $S1->fileno;

   $handle->set_handle( $S1 );

   is( $handle->read_handle,  $S1, '->read_handle now S1' );
   is( $handle->write_handle, $S1, '->write_handle now S1' );

   is_refcount( $handle, 2, '$handle latebound still has refcount 2 after set_handle' );

   is( $handle->notifier_name, "rw=$fd1", '$handle->notifier_name for late bind after handles' );

   $S2->syswrite( "readable" );

   wait_for { $readready };
   pass( '$handle latebound still invokes on_read_ready' );

   $loop->remove( $handle );
}

# ->socket and ->bind
{
   my $handle = IO::Async::Handle->new( on_read_ready => sub {}, on_write_ready => sub {} );

   $handle->socket( [ 'inet', 'stream', 0 ] );

   ok( defined $handle->read_handle, '->socket sets handle' );

   is( $handle->read_handle->sockdomain,       AF_INET,     'handle->sockdomain is AF_INET' );
   is( $handle->read_handle->sockopt(SO_TYPE), SOCK_STREAM, 'handle->socktype is SOCK_STREAM' );

   $handle->bind( { family => "inet", socktype => "dgram" } )->get;

   is( $handle->read_handle->sockopt(SO_TYPE), SOCK_DGRAM, 'handle->socktype is SOCK_DGRAM' );
   # Not sure what port number but it should be nonzero
   ok( ( unpack_sockaddr_in( $handle->read_handle->sockname ) )[0], 'handle->sockname has nonzero port' );
}

# Construction of IO::Handle from fileno
{
   my $handle = IO::Async::Handle->new(
      read_fileno => 0,
      on_read_ready => sub { },
   );

   ok( defined $handle->read_handle, '->new with read_fileno creates read_handle' );
   is( $handle->read_handle->fileno, 0, '->fileno of read_handle' );

   $handle = IO::Async::Handle->new(
      write_fileno => 1,
      on_write_ready => sub { },
   );

   ok( defined $handle->write_handle, '->new with write_fileno creates write_handle' );
   is( $handle->write_handle->fileno, 1, '->fileno of write_handle' );

   $handle = IO::Async::Handle->new(
      read_fileno  => 2,
      write_fileno => 2,
      on_read_ready  => sub { },
      on_write_ready => sub { },
   );

   identical( $handle->read_handle, $handle->write_handle,
      '->new with equal read and write fileno only creates one handle' );
}

done_testing;

package TestHandle;
use base qw( IO::Async::Handle );

sub on_read_ready  { $sub_readready = 1 }
sub on_write_ready { $sub_writeready = 1 }
