#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Feature::Compat::Class;

{
   my @called;

   class Test1 {
      ADJUST {
         push @called, "ADJUST-1";
      }

      ADJUST {
         push @called, "ADJUST-2";
      }
   }

   Test1->new();
   is_deeply( \@called, [qw( ADJUST-1 ADJUST-2 )], 'ADJUST blocks invoked in sequence' );
}

done_testing;
