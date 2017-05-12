#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;
use Event::Distributor;

# async->async
{
   my $dist = Event::Distributor->new;
   $dist->declare_signal( "alert" );

   my $called_f;
   my $called_dist;
   my @called_args;
   $dist->subscribe_async( alert => sub {
      $called_dist = shift;
      @called_args = @_;
      return $called_f = Future->new
   });

   my $f = $dist->fire_async( alert => "args", "here" );
   ok( $f, '->fire_async yields signal' );
   ok( !$f->is_ready, '$f not yet ready' );

   is( $called_dist, $dist, 'First arg to subscriber is $dist' );
   is_deeply( \@called_args, [ "args", "here" ], 'Args to subscriber' );

   $called_f->done();

   ok( $f->is_ready, '$f is now ready after $called_f->done' );

   is_deeply( [ $f->get ], [], '$f->get yields nothing' );
}

# pre-registration of subscriber
{
   my $dist = Event::Distributor->new;

   my $called;
   $dist->subscribe_sync( wibble => sub { $called++ } );

   $dist->declare_signal( "wibble" );
   $dist->fire_sync( wibble => );

   ok( $called, 'Preregistered subscriber is invoked' );
}

# subscribe_sync
{
   my $dist = Event::Distributor->new;
   $dist->declare_signal( "alert" );

   my $called;
   $dist->subscribe_sync( alert => sub { $called++ } );

   my $f = $dist->fire_async( alert => );

   ok( $f->is_ready, '$f already ready for only sync subscriber' );
   ok( $called, 'Synchronous subscriber actually called' );
}

# fire_sync
{
   my $dist = Event::Distributor->new;
   $dist->declare_signal( "alert" );

   $dist->subscribe_async( alert => sub { Future->done } );

   $dist->fire_sync( alert => );
   pass( 'Synchronous fire returns immediately' );
}

done_testing;
