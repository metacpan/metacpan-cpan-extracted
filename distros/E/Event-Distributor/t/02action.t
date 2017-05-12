#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Future;
use Event::Distributor::Action;

{
   my $act = Event::Distributor::Action->new;

   my $called_f;
   my @called_args;
   $act->subscribe( sub {
      @called_args = @_;
      return $called_f = Future->new;
   });

   my $f = $act->fire( "args", "here" );
   ok( $f, '->fire yields Future' );
   ok( !$f->is_ready, '$f not yet ready' );

   is_deeply( \@called_args, [ "args", "here" ], 'Args to subscriber' );

   $called_f->done( "result" );

   ok( $f->is_ready, '$f is now ready after $called_f->done' );

   is_deeply( [ $f->get ], [ "result" ], '$f->get yields subscriber result' );
}

# No subscribers
{
   my $act = Event::Distributor::Action->new;

   my $f = $act->fire();
   ok( $f->failure, '->fire with no subscribers fails' );
}

# Many subscribers
{
   my $act = Event::Distributor::Action->new;

   $act->subscribe( sub { } );

   ok( !defined eval { $act->subscribe( sub { } ); 1 },
      'Second ->subscribe fails' );
}

done_testing;
