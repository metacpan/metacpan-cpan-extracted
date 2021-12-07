#!/usr/bin/perl

use v5.26;
use warnings;
use experimental 'signatures';

use Test::More;

use Future::Workflow::Pipeline;

use Future::AsyncAwait 0.47;  # toplevel await
use Future;

# Synchronous output
{
   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output_sync( sub ( $result ) { push @finished, $result } );

   await $p->push_input( "one" );
   await $p->push_input( "two" );

   is_deeply( \@finished, [qw( one two )],
      '@finished after two items'
   );
}

# Synchronous stages
{
   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output_sync( sub ( $result ) { push @finished, $result } );

   $p->append_stage_sync( sub ( $item ) { return "$item-A" } );

   $p->append_stage_sync( sub ( $item ) { return "$item-B" } );

   await $p->push_input( "three" );

   is_deeply( \@finished, [qw( three-A-B )],
      '@finished after two stages'
   );
}

# Pipelining isn't synchronous
{
   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output_sync( sub ( $result ) { push @finished, $result } );

   my $f1;
   $p->append_stage( async sub ( $item ) { await $f1 = Future->new } );

   await $p->push_input( "item" );
   pass( '->push_input is not synchronous' );
   is( scalar @finished, 0, '@finished has no items' );

   $f1->done( "result" );
   is_deeply( \@finished, [qw( result )],
      '@finished after stage completed'
   );
}

done_testing;

