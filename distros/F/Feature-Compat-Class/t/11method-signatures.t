#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use Feature::Compat::Class;

class List {
   field @values;

   method push ( @more ) { push @values, @more }
   method nshift ( $n )  { splice @values, 0, $n }
}

{
   my $l = List->new;
   $l->push(qw( a b c d ));
   is_deeply( [ $l->nshift( 2 ) ],
      [qw( a b )],
      '$l->nshift yields values' );
}

class Test2 {
   field $name;
   ADJUST { $name = "Unit test" }

   method greet ( $message = "Hello, $name" ) {
      return $message;
   }
}

{
   my $obj = Test2->new;
   is( $obj->greet, "Hello, Unit test",
      'subroutine signature default exprs can see instance fields'
   );
}

done_testing;
