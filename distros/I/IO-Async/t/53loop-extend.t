#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Identity;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

# connect
{
   my %connectargs;
   my $connect_future;
   sub IO::Async::Loop::FOO_connect
   {
      my $self = shift;
      %connectargs = @_;

      identical( $self, $loop, 'FOO_connect invocant is $loop' );

      return $connect_future = $loop->new_future;
   }

   my $sock;
   my $f = $loop->connect(
      extensions => [qw( FOO )],
      some_param => "here",
      on_connected => sub { $sock = shift },
   );

   is( ref delete $connectargs{on_connected}, "CODE", 'FOO_connect received on_connected continuation' );
   is_deeply( \%connectargs,
              { some_param => "here" },
              'FOO_connect received some_param and no others' );

   identical( $f, $connect_future, 'FOO_connect returns Future object' );

   $loop->connect(
      extensions => [qw( FOO BAR )],
      param1 => "one",
      param2 => "two",
      on_connected => sub { $sock = shift },
   );

   delete $connectargs{on_connected};
   is_deeply( \%connectargs,
              { extensions => [qw( BAR )],
                param1 => "one",
                param2 => "two" },
              'FOO_connect still receives other extensions' );
}

# listen
{
   my %listenargs;
   my $listen_future;
   sub IO::Async::Loop::FOO_listen
   {
      my $self = shift;
      %listenargs = @_;

      identical( $self, $loop, 'FOO_listen invocant is $loop' );

      return $listen_future = $loop->new_future;
   }

   my $sock;
   my $f = $loop->listen(
      extensions => [qw( FOO )],
      some_param => "here",
      on_accept => sub { $sock = shift },
   );

   isa_ok( delete $listenargs{listener}, "IO::Async::Listener", '$listenargs{listener}' );
   is_deeply( \%listenargs,
              { some_param => "here" },
              'FOO_listen received some_param and no others' );

   identical( $f, $listen_future, 'FOO_listen returns Future object' );

   $loop->listen(
      extensions => [qw( FOO BAR )],
      param1 => "one",
      param2 => "two",
      on_accept => sub { $sock = shift },
   );

   delete $listenargs{listener};
   is_deeply( \%listenargs,
              { extensions => [qw( BAR )],
                param1 => "one",
                param2 => "two" },
              'FOO_listen still receives other extensions' );
}

done_testing;
