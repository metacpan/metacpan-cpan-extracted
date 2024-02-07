#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::Test;

use Test2::V0;

use IO::Async::Channel;

use IO::Async::OS;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

note( "Default IO::Async::Channel codec is " . IO::Async::Channel::_default_codec );

# sync->sync - mostly doesn't involve IO::Async
{
   my ( $pipe_rd, $pipe_wr ) = IO::Async::OS->pipepair;

   my $channel_rd = IO::Async::Channel->new;
   $channel_rd->setup_sync_mode( $pipe_rd );

   my $channel_wr = IO::Async::Channel->new;
   $channel_wr->setup_sync_mode( $pipe_wr );

   $channel_wr->send( [ structure => "here" ] );

   is( $channel_rd->recv, [ structure => "here" ], 'Sync mode channels can send/recv structures' );

   $channel_wr->send_encoded( $channel_wr->encode( [ prefrozen => "data" ] ) );

   is( $channel_rd->recv, [ prefrozen => "data" ], 'Sync mode channels can send_encoded' );

   $channel_wr->send_encoded( IO::Async::Channel->encode( [ prefrozen => "again" ] ) );

   is( $channel_rd->recv, [ prefrozen => "again" ], 'Channel->encode works as a class method' );

   $channel_wr->close;

   is( $channel_rd->recv, undef, 'Sync mode can be closed' );
}

# async->sync
{
   my ( $pipe_rd, $pipe_wr ) = IO::Async::OS->pipepair;

   my $channel_rd = IO::Async::Channel->new;
   $channel_rd->setup_sync_mode( $pipe_rd );

   my $channel_wr = IO::Async::Channel->new;
   $channel_wr->setup_async_mode( write_handle => $pipe_wr );

   $loop->add( $channel_wr );

   $channel_wr->send( [ data => "by async" ] );

   # Cheat for semi-sync
   my $flushed;
   $channel_wr->{stream}->write( "", on_flush => sub { $flushed++ } );
   wait_for { $flushed };

   is( $channel_rd->recv, [ data => "by async" ], 'Async mode channel can send' );

   $channel_wr->close;

   is( $channel_rd->recv, undef, 'Sync mode can be closed' );
}

# sync->async configured on_recv
{
   my ( $pipe_rd, $pipe_wr ) = IO::Async::OS->pipepair;

   my @recv_queue;
   my $recv_eof;

   my $channel_rd = IO::Async::Channel->new;
   $channel_rd->setup_async_mode( read_handle => $pipe_rd );

   $loop->add( $channel_rd );

   $channel_rd->configure(
      on_recv => sub {
         ref_is( $_[0], $channel_rd, 'Channel passed to on_recv' );
         push @recv_queue, $_[1];
      },
      on_eof => sub {
         $recv_eof++;
      },
   );

   my $channel_wr = IO::Async::Channel->new;
   $channel_wr->setup_sync_mode( $pipe_wr );

   $channel_wr->send( [ data => "by sync" ] );

   wait_for { @recv_queue };

   is( shift @recv_queue, [ data => "by sync" ], 'Async mode channel can on_recv' );

   $channel_wr->close;

   wait_for { $recv_eof };
   is( $recv_eof, 1, 'Async mode channel can on_eof' );
}

# sync->async oneshot ->recv with future
{
   my ( $pipe_rd, $pipe_wr ) = IO::Async::OS->pipepair;

   my $channel_rd = IO::Async::Channel->new;
   $channel_rd->setup_async_mode( read_handle => $pipe_rd );

   $loop->add( $channel_rd );

   my $channel_wr = IO::Async::Channel->new;
   $channel_wr->setup_sync_mode( $pipe_wr );

   $channel_wr->send( [ data => "by sync" ] );

   my $recv_f = wait_for_future $channel_rd->recv;

   is( scalar $recv_f->get, [ data => "by sync" ], 'Async mode future can receive data' );

   $channel_wr->close;

   my $eof_f = wait_for_future $channel_rd->recv;

   is( ( $eof_f->failure )[1], "eof", 'Async mode future can receive EOF' );
}

# sync->async oneshot ->recv with callbacks
{
   my ( $pipe_rd, $pipe_wr ) = IO::Async::OS->pipepair;

   my $channel_rd = IO::Async::Channel->new;
   $channel_rd->setup_async_mode( read_handle => $pipe_rd );

   $loop->add( $channel_rd );

   my $channel_wr = IO::Async::Channel->new;
   $channel_wr->setup_sync_mode( $pipe_wr );

   $channel_wr->send( [ data => "by sync" ] );

   my $recved;
   $channel_rd->recv(
      on_recv => sub {
         ref_is( $_[0], $channel_rd, 'Channel passed to ->recv on_recv' );
         $recved = $_[1];
      },
      on_eof => sub { die "Test failed early" },
   );

   wait_for { $recved };

   is( $recved, [ data => "by sync" ], 'Async mode channel can ->recv on_recv' );

   $channel_wr->close;

   my $recv_eof;
   $channel_rd->recv(
      on_recv => sub { die "Channel recv'ed when not expecting" },
      on_eof  => sub { $recv_eof++ },
   );

   wait_for { $recv_eof };
   is( $recv_eof, 1, 'Async mode channel can ->recv on_eof' );
}

# sync->async write once then close
{
   my ( $pipe_rd, $pipe_wr ) = IO::Async::OS->pipepair;

   my $channel_rd = IO::Async::Channel->new;
   $channel_rd->setup_async_mode( read_handle => $pipe_rd );

   $loop->add( $channel_rd );

   my $channel_wr = IO::Async::Channel->new;
   $channel_wr->setup_sync_mode( $pipe_wr );

   $channel_wr->send( [ "One value here" ] );
   $channel_wr->close;
   undef $channel_wr;

   my $recved;
   $channel_rd->recv(
      on_recv => sub {
         $recved = $_[1];
      },
      on_eof => sub { die "Test failed early" },
   );

   wait_for { $recved };

   is( $recved->[0], "One value here", 'Async mode channel can ->recv buffer at EOF' );

   $loop->remove( $channel_rd );
}

# Async ->recv cancellation
{
   my ( $pipe_rd, $pipe_wr ) = IO::Async::OS->pipepair;

   my $channel_rd = IO::Async::Channel->new;
   $channel_rd->setup_async_mode( read_handle => $pipe_rd );

   $loop->add( $channel_rd );

   my $channel_wr = IO::Async::Channel->new;
   $channel_wr->setup_sync_mode( $pipe_wr );

   $channel_wr->send( [ "first" ] );
   $channel_wr->send( [ "second" ] );

   my $r1_f = $channel_rd->recv;
   my $r2_f = $channel_rd->recv;

   $r1_f->cancel;

   wait_for { $r2_f->is_ready };

   is( scalar $r2_f->get, [ "second" ], 'Async recv result after cancellation' );

   $loop->remove( $channel_rd );
}

# Sereal encoder
SKIP: {
   skip "Sereal is not available", 1 unless
      defined eval { require Sereal::Encoder; require Sereal::Decoder };

   my ( $pipe_rd, $pipe_wr ) = IO::Async::OS->pipepair;

   my $channel_rd = IO::Async::Channel->new(
      codec => "Sereal"
   );
   $channel_rd->setup_async_mode( read_handle => $pipe_rd );

   $loop->add( $channel_rd );

   my $channel_wr = IO::Async::Channel->new(
      codec => "Sereal",
   );
   $channel_wr->setup_sync_mode( $pipe_wr );

   $channel_wr->send( [ data => "by sync" ] );

   my $recv_f = wait_for_future $channel_rd->recv;

   is( scalar $recv_f->get, [ data => "by sync" ], 'Channel can use Sereal as codec' );

   $loop->remove( $channel_rd );
}

done_testing;
