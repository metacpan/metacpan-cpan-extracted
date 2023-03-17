#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future;

use Future::AsyncAwait;

{
   my $f1 = Future->new;

   async sub with_failure
   {
      await $f1;
      Carp::confess "message here";
   }

   my $fret = with_failure();
   $f1->done;

   like( $fret->failure, qr/main::with_failure/,
      '$fret->failure message contains function name' );
}

done_testing;
