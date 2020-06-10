#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future::Buffer;

use Future;

my @next_fill_f;

my $buf = Future::Buffer->new(
   fill => sub { push @next_fill_f, my $f = Future->new; return $f },
);

# A quiescent buffer does not yet invoke fill
ok( !@next_fill_f, 'fill not yet invoked before any ->read' );

# A ->read call invokes fill to provide data
{
   my $read_f = $buf->read( 128 );

   ok( @next_fill_f, 'fill invoked after ->read' );
   ok( !$read_f->is_ready, '->read not yet ready' );

   ( shift @next_fill_f )->done( "abcd" );

   is( $read_f->get, "abcd", '->read yields data after fill' );
   ok( !@next_fill_f, 'fill not yet invoked again' );
}

# Two queued ->reads can see one round of fill
{
   my $read1 = $buf->read( 2 );
   my $read2 = $buf->read( 2 );

   ok( @next_fill_f, 'fill invoked after two reads' );

   ( shift @next_fill_f )->done( "efgh" );

   is( $read1->get, 'ef', 'first of two ->reads yields data after fill' );
   is( $read2->get, 'gh', 'second of two ->reads yields data after fill' );
}

# One long read will invoke multiple fills
{
   my $read_f = $buf->read_exactly( 4 );

   ( shift @next_fill_f )->done( "i" );
   ( shift @next_fill_f )->done( "j" );
   ( shift @next_fill_f )->done( "kl" );

   is( $read_f->get, "ijkl", '->read yields combined results of multiple fills' );
}

# fill future is used as prototype for read futures
{
   my $buf = Future::Buffer->new(
      fill => sub { return Some::Future::Subclass->new },
   );

   my $f = $buf->read( 1 );
   isa_ok( $f, "Some::Future::Subclass", '$f' );
}

done_testing;

package Some::Future::Subclass;
use base qw( Future );
