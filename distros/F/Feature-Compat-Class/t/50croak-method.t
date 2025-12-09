#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Feature::Compat::Class;

# This test checks that various error conditions result in exceptions being
# thrown. While the core implementation is still being developed we won't
# assert on the exact message text.

class Test1 {
   field $x;
   method clear { $x = 0 }
}

{
   ok( !defined eval { Test1->clear },
      'method on non-instance fails' );
}

{
   my $obj = bless [], "DifferentClass";

   ok( !defined eval { $obj->Test1::clear },
      'method on wrong class fails' );
}

done_testing;
