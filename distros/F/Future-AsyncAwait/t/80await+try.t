#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
   plan skip_all => "Future is not available"
      unless eval { require Future };
   plan skip_all => "Future::AsyncAwait >= 0.10 is not available"
      unless eval { require Future::AsyncAwait;
                    Future::AsyncAwait->VERSION( '0.10' ) };
   plan skip_all => "Syntax::Keyword::Try >= 0.07 is not available"
      unless eval { require Syntax::Keyword::Try;
                    Syntax::Keyword::Try->VERSION( '0.07' ) };

   Future::AsyncAwait->import;
   Syntax::Keyword::Try->import;

   diag( "Future::AsyncAwait $Future::AsyncAwait::VERSION, " .
         "Syntax::Keyword::Try $Syntax::Keyword::Try::VERSION" );
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
      catch {
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
      catch {}
      $fellthrough++;
      return "fallthrough";
   }

   my $f1 = Future->new;
   my $fdone = with_trycatch_return( $f1 );

   $f1->done;

   is( scalar $fdone->get, "result", '$fdone for successful await in try/catch with return' );
   ok( !$fellthrough, 'fallthrough after try{return} did not happen' );
}

# await in try/finally
{
   async sub with_tryfinally
   {
      my $f = shift;

      my $ret = "";

      try {
         await $f;
         $ret .= "T";
      }
      finally {
         $ret .= "F";
      }

      return $ret;
   }

   my $f1 = Future->new;
   my $fret = with_tryfinally( $f1 );

   $f1->done;

   is( scalar $fret->get, "TF", '$fret for await in try/finally' );
}

done_testing;
