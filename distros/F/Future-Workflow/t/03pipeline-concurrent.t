#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use experimental 'signatures';

use Future::Workflow::Pipeline;

use Future::AsyncAwait 0.47;  # toplevel await
use Future;

{
   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output( async sub ( $item ) { push @finished, $item } );

   my @f;
   $p->append_stage( async sub ( $item ) {
      push @f, my $f = Future->new;
      await $f;
   }, concurrent => 3 );

   await $p->push_input( "item-$_" ) for 1 .. 3;
   pass( '->push_input can enqueue multiple' );

   is( scalar @f, 3, 'three concurrent pending items' );

   ( shift @f )->done( "result" ) while @f;

   is( \@finished, [qw( result result result )],
      '@finished after stage completed'
   );
}

done_testing;
