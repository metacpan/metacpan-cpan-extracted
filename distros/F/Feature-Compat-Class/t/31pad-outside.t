#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Feature::Compat::Class;

{
   class Test1 {
      field $count;
      my $allcount = 0;

      method inc { $count++; $allcount++ }

      method count { $count }
      sub allcount { $allcount }
   }

   my $objA = Test1->new;
   my $objB = Test1->new;

   $objA->inc;
   $objB->inc;

   is( $objA->count, 1, '$objA->count' );
   is( Test1->allcount, 2, 'Test1->allcount' );
}

# anon methods can capture lexicals (RT132178)
{
   class Test2 {
      foreach my $letter (qw( x y z )) {
         my $code = method {
            return uc $letter;
         };

         no strict 'refs';
         *$letter = $code;
      }
   }

   my $obj = Test2->new;
   is( $obj->x, "X", 'generated anon method' );
   is( $obj->y, "Y", 'generated anon method' );
   is( $obj->z, "Z", 'generated anon method' );
}

done_testing;
