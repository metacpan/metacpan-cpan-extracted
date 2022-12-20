#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Feature::Compat::Class;

# We can't just clone many of the tests from Object-Pad/t/02field.t because a
# lot of those use init_expr

class Counter {
   field $count = 0;

   method inc { $count++ }

   method describe { "Count is now $count" }
}

{
   my $counter = Counter->new;
   $counter->inc;
   $counter->inc;
   $counter->inc;

   is( $counter->describe, "Count is now 3",
      '$counter->describe after $counter->inc x 3' );

   my $counter2 = Counter->new;
   is( $counter2->describe, "Count is now 0",
      '$counter2 has its own $count' );
}

# Basic init expressions
{
   class AllTheTypes {
      field $scalar = 123;
      field @array  = ( 45, 67 );
      field %hash   = ( 89 => 10 );

      method test {
         Test::More::is(        $scalar, 123,         '$scalar field' );
         Test::More::is_deeply( \@array, [ 45, 67 ],  '@array field' );
         Test::More::is_deeply( \%hash, { 89 => 10 }, '%hash field' );
      }
   }

   AllTheTypes->new->test;
}

# Fields are visible to string-eval()
{
   class Evil {
      field $field;

      method test {
         $field = "the value";
         ::is( eval '$field', "the value", 'fields are visible to string eval()' );
      }
   }

   Evil->new->test;
}

# fields can be captured by anon subs
{
   class ClosureCounter {
      field $count;

      method make_incrsub {
         return sub { $count++ };
      }

      method count { $count }
   }

   my $counter = ClosureCounter->new;
   my $inc = $counter->make_incrsub;

   $inc->();
   $inc->();

   is( $counter->count, 2, '->count after invoking incrsub x 2' );
}

# fields can be captured by anon methods
{
   class MClosureCounter {
      field $count;

      method make_incrmeth {
         return method { $count++ };
      }

      method count { $count }
   }

   my $counter = MClosureCounter->new;
   my $inc = $counter->make_incrmeth;

   $counter->$inc();
   $counter->$inc();

   is( $counter->count, 2, '->count after invoking incrmeth x 2' );
}

done_testing;
