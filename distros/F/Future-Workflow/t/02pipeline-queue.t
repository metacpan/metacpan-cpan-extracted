#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use experimental 'signatures';

use Future::Workflow::Pipeline;

use Future::AsyncAwait 0.47;  # toplevel await
use Future;

# items can be queued
{
   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output( async sub ( $item ) { push @finished, $item } );

   my $fstage;
   $p->append_stage( async sub ( $item ) { await $fstage = Future->new } );

   await $p->push_input( "item-$_" ) for 1 .. 3;
   pass( '3 items can be enqueued' );
   is( scalar @finished, 0, '@finished has no items' );

   $fstage->done( "result-1" );
   $fstage->done( "result-2" );
   $fstage->done( "result-3" );

   is( \@finished, [qw( result-1 result-2 result-3 )],
      '@finished after stages completed'
   );
}

# queue size can be limited
{
   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output( async sub ( $item ) { push @finished, $item } );

   my $fstage;
   $p->append_stage(
      async sub ( $item ) { await $fstage = Future->new },
      max_queue => 2,
   );

   await $p->push_input( "item-$_" ) for 1 .. 3;
   pass( '3 items can be enqueued' );
   is( scalar @finished, 0, '@finished has no items' );

   my $f = $p->push_input( "item-4" );
   ok( !$f->is_ready, '4th ->push_input is not yet ready' ) or
      $f->get;

   $fstage->done( "result-1" );

   ok( $f->is_ready, '4th ->push_input now ready with queue space' );

   $fstage->done( "result-2" );
   $fstage->done( "result-3" );
   $fstage->done( "result-4" );

   is( \@finished, [qw( result-1 result-2 result-3 result-4 )],
      '@finished after stages completed'
   );
}

# stage queues apply backpresure
{
   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output( async sub ( $item ) { push @finished, $item } );

   my $fA;
   $p->append_stage(
      async sub ( $item ) { await $fA = Future->new },
      max_queue => 0,
   );

   my $fB;
   $p->append_stage(
      async sub ( $item ) { await $fB = Future->new },
      max_queue => 0,
   );

   await $p->push_input( "item-1" );
   $fA->done( "result-1-A" );

   ok( defined $fB && !$fB->is_ready, 'second stage is working' );

   await $p->push_input( "item-2" );
   $fA->done( "result-2-A" );

   my $fpush = $p->push_input( "item-3" );
   ok( defined $fpush && !$fpush->is_ready, 'queue backpressure blocks push_input' );
}

done_testing;
