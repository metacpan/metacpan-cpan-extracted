#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

# await inside map
{
   my $ok = !eval q{
      async sub with_map
      {
         map {
            await $_[0];
         } 1 .. 3
      }
   };
   my $e = $@;

   ok( $ok, 'await in map fails to compile' );
   $ok and like( $e, qr/^await is not allowed inside map /, '' );
}

# await inside grep
{
   my $ok = !eval q{
      async sub with_grep
      {
         grep {
            await $_[0];
         } 1 .. 3
      }
   };
   my $e = $@;

   ok( $ok, 'await in grep fails to compile' );
   $ok and like( $e, qr/^await is not allowed inside grep /, '' );
}

done_testing;
