#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;
use Future::Utils qw( fmap_concat fmap_scalar );

# fmap_concat no concurrency
{
   my @subf;
   my $future = fmap_concat {
      return $subf[$_[0]] = Future->new
   } foreach => [ 0 .. 2 ];

   my @results;
   $future->on_done( sub { @results = @_ });

   $subf[0]->done( "A", "B" );
   $subf[1]->done( "C", "D", );
   $subf[2]->done( "E" );

   ok( $future->is_ready, '$future now ready after subs done for fmap_concat' );
   is_deeply( [ $future->get ], [qw( A B C D E )], '$future->get for fmap_concat' );
   is_deeply( \@results,        [qw( A B C D E )], '@results for fmap_concat' );
}

# fmap_concat concurrent
{
   my @subf;
   my $future = fmap_concat {
      return $subf[$_[0]] = Future->new
   } foreach => [ 0 .. 2 ],
     concurrent => 3;

   # complete out of order
   $subf[0]->done( "A", "B" );
   $subf[2]->done( "E" );
   $subf[1]->done( "C", "D" );

   is_deeply( [ $future->get ], [qw( A B C D E )], '$future->get for fmap_concat out of order' );
}

# fmap_scalar no concurrency
{
   my @subf;
   my $future = fmap_scalar {
      return $subf[$_[0]] = Future->new
   } foreach => [ 0 .. 2 ];

   my @results;
   $future->on_done( sub { @results = @_ });

   $subf[0]->done( "A" );
   $subf[1]->done( "B" );
   $subf[2]->done( "C" );

   ok( $future->is_ready, '$future now ready after subs done for fmap_scalar' );
   is_deeply( [ $future->get ], [qw( A B C )], '$future->get for fmap_scalar' );
   is_deeply( \@results,        [qw( A B C )], '@results for fmap_scalar' );
}

done_testing;
