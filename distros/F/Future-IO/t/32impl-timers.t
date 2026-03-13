#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Time::HiRes ();

my $overridden_time;
BEGIN {
   no warnings 'redefine';
   *Time::HiRes::time = sub () { return $overridden_time };
}

{
   package TestImplementation;
   use base qw( Future::IO::ImplBase );

   sub _new_future { Future->new }
}

# Check we can cancel middle timers and still allow later ones
{
   $overridden_time = 100;

   my @f = map { TestImplementation->sleep( 0.1 ) } 1 .. 5;

   my $timeout = TestImplementation->_timeout;
   ok( defined $timeout && $timeout > 0 && $timeout < 0.2,
      '->_timeout with queued timers' );

   $f[1]->cancel;
   $f[3]->cancel;

   $timeout = TestImplementation->_timeout;
   ok( defined $timeout && $timeout > 0 && $timeout < 0.2,
      '->_timeout after cancelled timers' );

   $overridden_time += 1;

   TestImplementation->_manage_timers;

   ok( $f[0]->is_done && $f[2]->is_done && $f[4]->is_done,
      'Non-cancelled timers are still invoked' )
}

# Cancelled timers don't count for _timeout
{
   $overridden_time = 200;

   my $f1 = TestImplementation->sleep( 0.1 );
   my $f2 = TestImplementation->sleep( 10 );

   cmp_ok( TestImplementation->_timeout, '<', 1.0,
      '_timeout before sleep 0.1 is cancelled' );

   $f1->cancel;

   cmp_ok( TestImplementation->_timeout, '>', 1.0,
      '_timeout after sleep 0.1 is cancelled' );

   $f2->cancel;
}

# Try to trigger the queue compaction logic
{
   $overridden_time = 300;

   my @f;
   push @f, TestImplementation->sleep( 0.1 ) while @f < 100;

   my $lastf = pop @f;
   $_->cancel for @f;
}

# Timers can be enqueueed all out of order and still work correctly
{
   $overridden_time = 400;

   my @futures = map { [ $_, TestImplementation->sleep( $_ ) ] } ( 1, 5, 3, 2, 4 );
   @futures = map { $_->[1] } sort { $a->[0] <=> $b->[0] } @futures;

   foreach my $idx ( 0 .. 4 ) {
      $overridden_time += 1;

      TestImplementation->_manage_timers;
      ok( $futures[$idx]->is_ready, "Future ready at tick $idx" );
      ok( !$futures[$idx+1]->is_ready, "Next future not yet ready at tick $idx" )
         if $idx < 4;
   }
}

done_testing;
