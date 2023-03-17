#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use feature 'signatures';
no warnings 'experimental';

use Future::AsyncAwait;

{
   async sub add ( $x, $y )
   {
      return $x + $y;
   }

   my $f = add( 2, 3 );
   is( $f->get, 5, 'add(2,3)' );
}

# return in argument default still Future-wraps
{
   async sub identity ( $x, $y = return $x ) { }

   my $f = identity( 123 );
   isa_ok( $f, [ "Future" ], '$f' );
   is( $f->get, 123, '$f->get on return in arg default' );
}

# argcount exceptions are thrown synchronously
{
   async sub one_arg ( $x ) { return $x; }

   like( dies { my $f = one_arg() },
      qr/^Too few arguments for subroutine 'main::one_arg'/,
      'argcheck failure happens synchronously' );

   like( dies { my $f = one_arg( 1, 2 ) },
      qr/^Too many arguments for subroutine 'main::one_arg'/,
      'argcheck failure happens synchronously' );
}

# The following are additional tests that our pre-5.31.3 backported
# parse_subsignature() works correctly
{
   async sub sum ( @x ) {
      my $ret = 0;
      $ret += $_ for @x;
      return $ret;
   }

   my $f = sum( 10, 20, 30 );
   is( $f->get, 60, 'parsed slurpy parameter' );

   async sub firstandthird($x, $, $z) {
      return $x . $z;
   }

   $f = firstandthird(qw( a b c ));
   is( $f->get, "ac", 'parsed unnamed parameter' );

   async sub withdefault ( $one = 1, $two = 2 ) {
      return $one + $two;
   }

   $f = withdefault();
   is( $f->get, 3, 'parsed parameters with default expr' );
}

# RT131571
{
   ok( defined eval q{
      use experimental 'signatures';
      async sub func :method ( $self, @args ) { }
      1;
   }, 'signatures do not leak into attributes (RT131571)' ) or
      diag( "Error was $@" );
}

done_testing;
