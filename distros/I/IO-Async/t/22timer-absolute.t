#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::Test;

use Test2::V0 0.000149;

use lib ".";
use t::TimeAbout;

use Time::HiRes qw( time );

use IO::Async::Timer::Absolute;

use IO::Async::Loop;

use constant AUT => $ENV{TEST_QUICK_TIMERS} ? 0.1 : 1;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

{
   my $expired;
   my @eargs;

   my $timer = IO::Async::Timer::Absolute->new(
      time => time + 2 * AUT,

      on_expire => sub { @eargs = @_; $expired = 1 },
   );

   ok( defined $timer, '$timer defined' );
   isa_ok( $timer, [ "IO::Async::Timer" ], '$timer isa IO::Async::Timer' );

   is_oneref( $timer, '$timer has refcount 1 initially' );

   $loop->add( $timer );

   is_refcount( $timer, 2, '$timer has refcount 2 after adding to Loop' );

   ok( $timer->is_running, 'Started Timer is running' );

   time_about( sub { wait_for { $expired } }, 2, 'Timer works' );
   is( \@eargs, [ exact_ref($timer) ], 'on_expire args' );

   ok( !$timer->is_running, 'Expired Timer is no longer running' );

   undef @eargs;

   is_refcount( $timer, 2, '$timer has refcount 2 before removing from Loop' );

   $loop->remove( $timer );

   is_oneref( $timer, '$timer has refcount 1 after removing from Loop' );
}

{
   my $expired;

   my $timer = IO::Async::Timer::Absolute->new(
      time => time + 2 * AUT,
      on_expire => sub { $expired++ },
   );

   $loop->add( $timer );
   $loop->remove( $timer );

   $loop->loop_once( 3 * AUT );

   ok( !$expired, "Removed Timer does not expire" );
}

{
   my $expired;

   my $timer = IO::Async::Timer::Absolute->new(
      time => time + 5 * AUT,
      on_expire => sub { $expired++ },
   );

   $loop->add( $timer );

   $timer->configure( time => time + 1 * AUT );

   time_about( sub { wait_for { $expired } }, 1, 'Reconfigured timer works' );

   $loop->remove( $timer );
}

{
   my $timer = IO::Async::Timer::Absolute->new(
      time => time + 1 * AUT,
      on_expire => sub { die "Test failed to replace expiry handler" },
   );

   $loop->add( $timer );

   my $new_expired;
   $timer->configure( on_expire => sub { $new_expired = 1 } );

   time_about( sub { wait_for { $new_expired } }, 1, 'Reconfigured timer on_expire works' );

   $loop->remove( $timer );
}

## Subclass

my $sub_expired;
{
   my $timer = TestTimer->new(
      time => time + 2 * AUT,
   );

   ok( defined $timer, 'subclass $timer defined' );
   isa_ok( $timer, [ "IO::Async::Timer" ], 'subclass $timer isa IO::Async::Timer' );

   is_oneref( $timer, 'subclass $timer has refcount 1 initially' );

   $loop->add( $timer );

   is_refcount( $timer, 2, 'subclass $timer has refcount 2 after adding to Loop' );

   ok( $timer->is_running, 'Started subclass Timer is running' );

   time_about( sub { wait_for { $sub_expired } }, 2, 'subclass Timer works' );

   ok( !$timer->is_running, 'Expired subclass Timer is no longer running' );

   is_refcount( $timer, 2, 'subclass $timer has refcount 2 before removing from Loop' );

   $loop->remove( $timer );

   is_oneref( $timer, 'subclass $timer has refcount 1 after removing from Loop' );
}

done_testing;

package TestTimer;
use base qw( IO::Async::Timer::Absolute );

sub on_expire { $sub_expired = 1 }
