#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0 0.000149;
use Test::Metrics::Any;

use IO::Async::Notifier;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new;
is_refcount( $loop, 2, '$loop has refcount 2 initially' );

{
   package TestNotifier;
   use base qw( IO::Async::Notifier );

   sub new
   {
      my $self = shift->SUPER::new;
      ( $self->{varref} ) = @_;
      return $self;
   }

   sub _add_to_loop
   {
      my $self = shift;
      ${ $self->{varref} } = 1;
   }

   sub _remove_from_loop
   {
      my $self = shift;
      ${ $self->{varref} } = 0;
   }
}

# $loop->add
{
   my $notifier = TestNotifier->new( \my $in_loop );

   is( [ $loop->notifiers ],
              [],
              '$loop->notifiers empty' );
   is( $notifier->loop, undef, 'loop undef' );

   $loop->add( $notifier );

   is_refcount( $loop, 2, '$loop has refcount 2 adding Notifier' );
   is_refcount( $notifier, 2, '$notifier has refcount 2 after adding to Loop' );

   ref_is( $notifier->loop, $loop, 'loop $loop' );

   is( [ $loop->notifiers ],
              [ exact_ref($notifier) ],
              '$loop->notifiers contains new Notifier' );

   ok( $in_loop, '_add_to_loop called' );

   ok( dies { $loop->add( $notifier ) }, 'adding again produces error' );

   $loop->remove( $notifier );

   is( $notifier->loop, undef, '$notifier->loop is undef' );

   is( [ $loop->notifiers ],
              [],
              '$loop->notifiers empty once more' );

   ok( !$in_loop, '_remove_from_loop called' );

   is_oneref( $notifier, '$notifier has refcount 1 finally' );
}

# parent/child in Loop
{
   my $parent = TestNotifier->new( \my $parent_in_loop );
   my $child = TestNotifier->new( \my $child_in_loop );

   $loop->add( $parent );

   $parent->add_child( $child );

   is_refcount( $child, 3, '$child has refcount 3 after add_child within loop' );

   ref_is( $parent->loop, $loop, '$parent->loop is $loop' );
   ref_is( $child->loop,  $loop, '$child->loop is $loop' );

   ok( $parent_in_loop, '$parent now in loop' );
   ok( $child_in_loop,  '$child now in loop' );

   ok( dies { $loop->remove( $child ) }, 'Directly removing a child from the loop fails' );

   $loop->remove( $parent );

   is( [ $parent->children ], [ exact_ref($child) ], '$parent->children after $loop->remove' );

   is_oneref( $parent, '$parent has refcount 1 after removal from loop' );
   is_refcount( $child, 2, '$child has refcount 2 after removal of parent from loop' );

   is( $parent->loop, undef, '$parent->loop is undef' );
   is( $child->loop,  undef, '$child->loop is undef' );

   ok( !$parent_in_loop, '$parent no longer in loop' );
   ok( !$child_in_loop,  '$child no longer in loop' );

   ok( dies { $loop->add( $child ) }, 'Directly adding a child to the loop fails' );

   $loop->add( $parent );

   ref_is( $child->loop, $loop, '$child->loop is $loop after remove/add parent' );

   ok( $parent_in_loop, '$parent now in loop' );
   ok( $child_in_loop,  '$child now in loop' );

   $loop->remove( $parent );

   $parent->remove_child( $child );

   is_oneref( $parent, '$parent has refcount 1 finally' );
   is_oneref( $child,  '$child has refcount 1 finally' );
}

# Metrics
SKIP: {
   skip "Metrics are unavailable" unless $IO::Async::Metrics::METRICS;

   my $notifier = TestNotifier->new( \my $tmp );

   $loop->add( $notifier );

   is_metrics( { io_async_notifiers => 1 },
      '$loop->add increments notifiers count' );

   $loop->remove( $notifier );

   is_metrics( { io_async_notifiers => 0 },
      '$loop->remove decrements notifiers count' );
}

is_refcount( $loop, 2, '$loop has refcount 2 finally' );

done_testing;
