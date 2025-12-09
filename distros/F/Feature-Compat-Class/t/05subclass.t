#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Feature::Compat::Class;

{
   class Test1Base {
      method describe {
         "Value is " . $self->m;
      }
   }
   class Test1Derived :isa(Test1Base) {
      method m { 123 }
   }

   my $obj = Test1Derived->new;
   isa_ok( $obj, [ "Test1Derived" ], '$obj' );
   isa_ok( $obj, [ "Test1Base" ],    '$obj' );
   is( $obj->describe, "Value is 123", 'Object can invoke superclass methods' );
}

done_testing;
