#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;
use Event::Distributor::Query;

{
   my $query = Event::Distributor::Query->new;

   $query->subscribe( sub {
      Future->done( "The result", "here" );
   });

   my @result = $query->fire->get;

   is_deeply( \@result, [ "The result", "here" ], 'result of query event' );
}

# two sync subscribers
{
   my $query = Event::Distributor::Query->new;

   my $called;
   $query->subscribe( sub { $called++; Future->done( 123 ) } );
   $query->subscribe( sub { $called++; Future->done( 456 ) } );

   my $result = $query->fire->get;

   is( $result, 123, 'query event takes first result' );
   is( $called, 1, 'query event does not invoke later sync subscribers' );
}

# no subscribers
{
   my $query = Event::Distributor::Query->new;

   my $result = $query->fire->get;
   is( $result, undef, 'query yields undef with no subscribers' );
}

# empty result counts as failure
{
   my $query = Event::Distributor::Query->new;

   $query->subscribe( sub { Future->done() } );
   $query->subscribe( sub { Future->done( "second" ) } );

   is( scalar $query->fire->get, "second", 'query considers empty results failures' );
}

# all empty results yields empty result
{
   my $query = Event::Distributor::Query->new;

   $query->subscribe( sub { Future->done() } );

   my $f = $query->fire;

   ok( !$f->is_failed, 'query yielding empty result does not fail' );
   is_deeply( [ $f->get ], [], 'query yields empty result' );
}

done_testing;
