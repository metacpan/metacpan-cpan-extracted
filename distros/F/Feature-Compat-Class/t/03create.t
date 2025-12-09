#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Feature::Compat::Class;

{
   my @called;
   my $class_in_ADJUST;

   class Test1 {
      ADJUST {
         push @called, "ADJUST-1";
      }

      ADJUST {
         push @called, "ADJUST-2";
         $class_in_ADJUST = __CLASS__;
      }
   }

   Test1->new();
   is( \@called, [qw( ADJUST-1 ADJUST-2 )], 'ADJUST blocks invoked in sequence' );

   is( $class_in_ADJUST, "Test1", '__CLASS__ during ADJUST block' );
}

done_testing;
