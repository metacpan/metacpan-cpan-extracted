#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Feature::Compat::Class;

class Test1 {
   field $count;

   method inc { $count++ };
   method make_incrsub {
      return sub { $count++ };
   }

   method count { $count }
}

{
   my $obj = Test1->new;
   my $inc = $obj->make_incrsub;

   $inc->();
   $inc->();

   is( $obj->count, 2, '->count after invoking incrsub' );
}

done_testing;
