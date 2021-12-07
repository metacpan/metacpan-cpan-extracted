#!/usr/bin/perl

use v5.26;
use warnings;
use experimental 'signatures';

use Test::More;

use Future::Workflow::Pipeline;

use Future::AsyncAwait 0.47;  # toplevel await
use Future;

# No stages at all
{
   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output( async sub ( $item ) {
      push @finished, $item;
   });

   await $p->push_input( "one" );
   await $p->push_input( "two" );

   is_deeply( \@finished, [qw( one two )],
      '@finished after two items'
   );
}

# Two stages
{
   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output( async sub ( $item ) { push @finished, $item } );

   $p->append_stage( async sub ( $item ) { return "$item-A" } );

   $p->append_stage( async sub ( $item ) { return "$item-B" } );

   await $p->push_input( "three" );

   is_deeply( \@finished, [qw( three-A-B )],
      '@finished after two stages'
   );
}

# Pipelining isn't synchronous
{
   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output( async sub ( $item ) { push @finished, $item } );

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
