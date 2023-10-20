#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future::Buffer;

use Future;

my @next_fill_f;

my $buf = Future::Buffer->new(
   fill => sub { push @next_fill_f, my $f = Future->new; return $f },
);

# A quiescent buffer does not yet invoke fill
ok( !@next_fill_f, 'fill not yet invoked before any ->read_atmost' );

# A ->read_atmost call invokes fill to provide data
{
   my $read_f = $buf->read_atmost( 128 );

   ok( @next_fill_f, 'fill invoked after ->read_atmost' );
   ok( !$read_f->is_ready, '->read_atmost not yet ready' );

   ( shift @next_fill_f )->done( "abcd" );

   is( $read_f->get, "abcd", '->read_atmost yields data after fill' );
   ok( !@next_fill_f, 'fill not yet invoked again' );
}

# Two queued ->reads can see one round of fill
{
   my $read1 = $buf->read_atmost( 2 );
   my $read2 = $buf->read_atmost( 2 );

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

   is( $read_f->get, "ijkl", '->read_atmost yields combined results of multiple fills' );
}

# One long fill is shared between multiple reads
{
   my $read1 = $buf->read_atmost( 1 );
   ( shift @next_fill_f )->done( "mno" );
   my $read2 = $buf->read_atmost( 2 );

   ok( !@next_fill_f, 'fill not invoked while pending data is sufficient' );
   is( $read1->get, "m",  'first of two ->reads yields data from shared fill' );
   is( $read2->get, "no", 'second of two ->reads yields data from shared fill' );
}

# Read futures can be cancelled
{
   my $f1 = $buf->read_atmost( 5 );
   my $f2 = $buf->read_atmost( 5 );

   $f1->cancel;

   ( shift @next_fill_f )->done( "pq" );
   is( $f2->get, "pq", 'Second ->read_atmost receives data when first is cancelled' );
}

# Read future cancellation is propagated to fill future
{
   my $f1 = $buf->read_atmost( 5 );
   my $fill1 = shift @next_fill_f;

   $f1->cancel;
   ok( $fill1->is_cancelled, 'Pending fill future is cancelled' );

   my $f2 = $buf->read_atmost( 5 );
   my $fill2 = shift @next_fill_f;

   ok( !$fill2->is_ready, 'Second fill future is issued after first cancelled' );

   $fill2->done( "rst" );
   is( $f2->get, "rst", 'Second ->read_atmost receives data after second fill future' );
}

# fill future is used as prototype for read futures
{
   my $buf = Future::Buffer->new(
      fill => sub { return Some::Future::Subclass->new },
   );

   my $f = $buf->read_atmost( 1 );
   isa_ok( $f, [ "Some::Future::Subclass" ], '$f' );
}

done_testing;

package Some::Future::Subclass;
use base qw( Future );
