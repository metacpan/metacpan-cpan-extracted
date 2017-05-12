#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Future;
use Event::Distributor::Signal;

# async->async
{
   my $sig = Event::Distributor::Signal->new;

   my $called_f;
   my @called_args;
   $sig->subscribe( sub {
      @called_args = @_;
      return $called_f = Future->new
   });

   my $f = $sig->fire( "args", "here" );
   ok( $f, '->fire yields Future' );
   ok( !$f->is_ready, '$f not yet ready' );

   is_deeply( \@called_args, [ "args", "here" ], 'Args to subscriber' );

   $called_f->done();

   ok( $f->is_ready, '$f is now ready after $called_f->done' );

   is_deeply( [ $f->get ], [], '$f->get yields nothing' );
}

# two subscribers
{
   my $sig = Event::Distributor::Signal->new;

   my $f1;
   $sig->subscribe( sub { $f1 = Future->new } );

   my $f2;
   $sig->subscribe( sub { $f2 = Future->new } );

   my $f = $sig->fire;

   ok( $f1 && $f2, 'Both subscribers invoked' );

   $f1->done;
   ok( !$f->is_ready, 'Result future still waiting after $f1->done' );

   $f2->done;
   ok( $f->is_ready, 'Result future now done after $f2->done' );
}

# failure
{
   my $sig = Event::Distributor::Signal->new;

   $sig->subscribe( sub { die "Failure" } );

   my $called;
   $sig->subscribe( sub { $called++; Future->done } );

   like( exception { $sig->fire->get },
         qr/^Failure /,
         '->fire_sync raises exception' );
   ok( $called, 'second subscriber still invoked after first failure' );
}

# Multiple failures
{
   my $sig = Event::Distributor::Signal->new;

   $sig->subscribe( sub { die "One failed\n" } );
   $sig->subscribe( sub { die "Two failed\n" } );

   is( exception { $sig->fire->get },
      "Multiple subscribers failed:\n" .
      " | One failed\n" .
      " | Two failed\n",
      '->fire_sync raises special multiple failure' );
}

# subscribers cannot corrupt object by $_ leakage
{
   my $sig = Event::Distributor::Signal->new;

   my $called;
   $sig->subscribe( sub { $called++; undef $_; Future->done } );

   Future->needs_all(
      $sig->fire( whail => ),
      $sig->fire( whail => ),
   )->get;

   is( $called, 2, 'Subscriber invoked twice' );
}

done_testing;
