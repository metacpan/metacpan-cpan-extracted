#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   plan skip_all => "Future is not available"
      unless eval { require Future };
   plan skip_all => "Future::AsyncAwait >= 0.31_001 is not available"
      unless eval { require Future::AsyncAwait;
                    Future::AsyncAwait->VERSION( '0.31001' ) };
   plan skip_all => "Syntax::Keyword::Dynamically >= 0.01 is not available"
      unless eval { require Syntax::Keyword::Dynamically;
                    Syntax::Keyword::Dynamically->VERSION( '0.01' ) };

   Future::AsyncAwait->import;
   Syntax::Keyword::Dynamically->import;

   diag( "Future::AsyncAwait $Future::AsyncAwait::VERSION, " .
         "Syntax::Keyword::Dynamically $Syntax::Keyword::Dynamically::VERSION" );
}

{
   my $var = 1;
   async sub with_dynamically
   {
      my $f = shift;

      dynamically $var = 2;

      is( $var, 2, '$var is 2 before await' );
      await $f;
      is( $var, 2, '$var is 2 after await' );

      return "result";
   }

   my $f1 = Future->new;
   my $fret = with_dynamically( $f1 );

   is( $var, 1, '$var is 1 while suspended' );

   $f1->done;
   is( scalar $fret->get, "result", '$fret for dynamically in async sub' );
   is( $var, 1, '$var is 1 after finish' );
}

done_testing;
