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
   plan skip_all => "Feature::Compat::Try is not available"
      unless eval { require Feature::Compat::Try };

   Future::AsyncAwait->import;
   Feature::Compat::Try->import;

   diag( "Future::AsyncAwait $Future::AsyncAwait::VERSION, " .
         "Feature::Compat::Try $Feature::Compat::Try::VERSION" );
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

done_testing;
