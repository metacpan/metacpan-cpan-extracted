#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::Test;

use Test2::V0 0.000149;

use lib ".";
use t::TimeAbout;

use Time::HiRes qw( time );

use IO::Async::Timer::Countdown;

use IO::Async::Loop;

use constant AUT => $ENV{TEST_QUICK_TIMERS} ? 0.1 : 1;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

{
   my $expired;
   my @eargs;

   my $timer = IO::Async::Timer::Countdown->new(
      delay => 2 * AUT,

      on_expire => sub { @eargs = @_; $expired = 1 },
   );

   ok( defined $timer, '$timer defined' );
   isa_ok( $timer, [ "IO::Async::Timer" ], '$timer isa IO::Async::Timer' );

   is_oneref( $timer, '$timer has refcount 1 initially' );

   $loop->add( $timer );

   is_refcount( $timer, 2, '$timer has refcount 2 after adding to Loop' );

   ok( !$timer->is_running, 'New Timer is no yet running' );
   ok( !$timer->is_expired, 'New Timer is no yet expired' );

   ref_is( $timer->start, $timer, '$timer->start returns $timer' );

   is_refcount( $timer, 2, '$timer has refcount 2 after starting' );

   ok(  $timer->is_running, 'Started Timer is running' );
   ok( !$timer->is_expired, 'Started Timer not yet expired' );

   time_about( sub { wait_for { $expired } }, 2, 'Timer works' );
   is( \@eargs, [ exact_ref($timer) ], 'on_expire args' );

   ok( !$timer->is_running, 'Expired Timer is no longer running' );
   ok(  $timer->is_expired, 'Expired Timer now expired' );

   undef @eargs;

   is_refcount( $timer, 2, '$timer has refcount 2 before removing from Loop' );

   $loop->remove( $timer );

   is_oneref( $timer, '$timer has refcount 1 after removing from Loop' );

   undef $expired;

   is( $timer->start, $timer, '$timer->start out of a Loop returns $timer' );

   $loop->add( $timer );

   ok(  $timer->is_running, 'Re-started Timer is running' );
   ok( !$timer->is_expired, 'Re-started Timer not yet expired' );

   time_about( sub { wait_for { $expired } }, 2, 'Timer works a second time' );

   ok( !$timer->is_running, '2nd-time expired Timer is no longer running' );
   ok(  $timer->is_expired, '2nd-time expired Timer now expired' );

   undef $expired;
   $timer->start;

   $loop->loop_once( 1 * AUT );

   $timer->stop;

   $timer->stop;

   ok( 1, "Timer can be stopped a second time" );

   $loop->loop_once( 2 * AUT );

   ok( !$expired, "Stopped timer doesn't expire" );

   undef $expired;
   $timer->start;

   $loop->loop_once( 1 * AUT );

   my $now = time;
   $timer->reset;

   $loop->loop_once( 1.5 * AUT );

   ok( !$expired, "Reset Timer hasn't expired yet" );

   wait_for { $expired };
   my $took = (time - $now) / AUT;

   cmp_ok( $took, '>', 1.5, "Timer has now expired took at least 1.5" );
   cmp_ok( $took, '<', 2.5, "Timer has now expired took no more than 2.5" );

   $loop->remove( $timer );

   undef @eargs;

   is_oneref( $timer, 'Timer has refcount 1 finally' );
}

{
   my $timer = IO::Async::Timer::Countdown->new(
      delay => 2 * AUT,
      on_expire => sub { },
   );

   $loop->add( $timer );

   $timer->start;

   $loop->remove( $timer );

   $loop->loop_once( 3 * AUT );

   ok( !$timer->is_expired, "Removed Timer does not expire" );
}

{
   my $timer = IO::Async::Timer::Countdown->new(
      delay => 2 * AUT,
      on_expire => sub { },
   );

   $timer->start;

   $loop->add( $timer );

   ok( $timer->is_running, 'Pre-started Timer is running after adding' );

   time_about( sub { wait_for { $timer->is_expired } }, 2, 'Pre-started Timer works' );

   $loop->remove( $timer );
}

{
   my $timer = IO::Async::Timer::Countdown->new(
      delay => 2 * AUT,
      on_expire => sub { },
   );

   $timer->start;
   $timer->stop;

   $loop->add( $timer );

   $loop->loop_once( 3 * AUT );

   ok( !$timer->is_expired, "start/stopped Timer doesn't expire" );

   $loop->remove( $timer );
}

{
   my $timer = IO::Async::Timer::Countdown->new(
      delay => 2 * AUT,
      on_expire => sub { },
   );

   $loop->add( $timer );

   $timer->configure( delay => 1 * AUT );

   $timer->start;

   time_about( sub { wait_for { $timer->is_expired } }, 1, 'Reconfigured timer delay works' );

   my $expired;
   $timer->configure( on_expire => sub { $expired = 1 } );

   $timer->start;

   time_about( sub { wait_for { $expired } }, 1, 'Reconfigured timer on_expire works' );

   $timer->start;
   ok( dies { $timer->configure( delay => 5 ); },
       'Configure a running timer fails' );

   $loop->remove( $timer );
}

{
   my $timer = IO::Async::Timer::Countdown->new(
      delay => 1 * AUT,
      remove_on_expire => 1,

      on_expire => sub { },
   );

   $loop->add( $timer );
   $timer->start;

   time_about( sub { wait_for { $timer->is_expired } }, 1, 'remove_on_expire Timer' );

   is( $timer->loop, undef, 'remove_on_expire Timer removed from Loop after expire' );
}

## Subclass

my $sub_expired;
{
   my $timer = TestTimer->new(
      delay => 2 * AUT,
   );

   ok( defined $timer, 'subclass $timer defined' );
   isa_ok( $timer, [ "IO::Async::Timer" ], 'subclass $timer isa IO::Async::Timer' );

   is_oneref( $timer, 'subclass $timer has refcount 1 initially' );

   $loop->add( $timer );

   is_refcount( $timer, 2, 'subclass $timer has refcount 2 after adding to Loop' );

   $timer->start;

   is_refcount( $timer, 2, 'subclass $timer has refcount 2 after starting' );

   ok( $timer->is_running, 'Started subclass Timer is running' );

   time_about( sub { wait_for { $sub_expired } }, 2, 'subclass Timer works' );

   ok( !$timer->is_running, 'Expired subclass Timer is no longer running' );

   is_refcount( $timer, 2, 'subclass $timer has refcount 2 before removing from Loop' );

   $loop->remove( $timer );

   is_oneref( $timer, 'subclass $timer has refcount 1 after removing from Loop' );
}

done_testing;

package TestTimer;
use base qw( IO::Async::Timer::Countdown );

sub on_expire { $sub_expired = 1 }
