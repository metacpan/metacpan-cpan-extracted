#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   plan skip_all => "Future is not available"
      unless eval { require Future };
   plan skip_all => "Future::AsyncAwait >= 0.10 is not available"
      unless eval { require Future::AsyncAwait;
                    Future::AsyncAwait->VERSION( '0.10' ) };
   plan skip_all => "feature 'try' is not available"
      unless $] >= 5.033007;

   Future::AsyncAwait->import;

   require feature;
   feature->import( 'try' );
   warnings->unimport( 'experimental::try' );

   diag( "Future::AsyncAwait $Future::AsyncAwait::VERSION, " .
         "core perl version $^V" );
}

# await in try/catch
{
   async sub with_trycatch
   {
      my $f = shift;

      my $ret;

      try {
         await $f;
         $ret = "result";
      }
      catch ($e) {
         $ret = "oopsie";
      }
      return $ret;
   }

   my $f1 = Future->new;
   my $fdone = with_trycatch( $f1 );

   $f1->done;
   is( scalar $fdone->get, "result", '$fdone for successful await in try/catch' );

   my $f2 = Future->new;
   my $ffail = with_trycatch( $f2 );

   $f2->fail( "fail" );
   is( scalar $ffail->get, "oopsie", '$ffail for failed await in try/catch' );
}

# await in try/catch with return
{
   my $fellthrough;

   async sub with_trycatch_return
   {
      my $f = shift;

      try {
         await $f;
         return "result";
      }
      catch ($e) {}
      $fellthrough++;
      return "fallthrough";
   }

   my $f1 = Future->new;
   my $fdone = with_trycatch_return( $f1 );

   $f1->done;

   is( scalar $fdone->get, "result", '$fdone for successful await in try/catch with return' );
   ok( !$fellthrough, 'fallthrough after try{return} did not happen' );
}

# await in try/catch list context (RT134790)
{
   async sub return_list { return ( "first", "second" ); }

   async sub await_return_list
   {
      try {
         return await return_list();
      }
      catch ($e) { die $e; }
   }

   my ( $r1, $r2 ) = await await_return_list();
   is( $r1, "first",  'first result from try/return list' );
   is( $r2, "second", 'second result from try/return list' );
}

# await in toplevel try
{
   try {
      is( await Future->done( "success" ), "success",
         'await in toplevel try' );
   }
   catch ($e) {
      fail( 'await in toplevel try' );
   }

   try {
      await Future->fail( "failure\n" );
   }
   catch ($e) {
      is( $e, "failure\n", 'await in toplevel try/catch failure' );
   }
}

done_testing;
