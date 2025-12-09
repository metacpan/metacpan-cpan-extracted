#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Feature::Compat::Class;

# We can't just clone many of the tests from Object-Pad/t/01method.t because a
# lot of those use `BUILD` blocks
#
# We'll mostly copy core perl's t/class/class.t and t/class/method.t instead

{
   class Test1 {
      method hello { return "Hello, world!" }

      method classname { return __CLASS__; }
   }

   my $obj = Test1->new;
   isa_ok( $obj, [ "Test1" ], '$obj' );

   is( $obj->hello, "Hello, world!", '$obj->hello' );

   is( $obj->classname, "Test1", '$obj->classname yields __CLASS__' );
}

# $self in method
{
   class Test2 {
      method retself { return $self }
   }

   my $obj = Test2->new;
   is( $obj->retself, $obj, '$self inside method' );
}

# $self is shifted from @_
{
   class Test3 {
      method args { return @_ }
   }

   my $obj = Test3->new;
   is( [ $obj->args( "a", "b" ) ], [ "a", "b" ],
      '$self is shifted from @_' );
}

# anonymous methods
{
   class Test4 {
      method genanon {
         return method { "Result" };
      }
   }

   my $obj = Test4->new;
   my $mref = $obj->genanon;

   is( $obj->$mref, "Result", 'anonymous method can be invoked' );
}

done_testing;
