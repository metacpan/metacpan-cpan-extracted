use v5.10;
use strict;
use warnings;

use Test::More;

use Future;

# wrap
{
   my $f = Future->new;

   my $future = Future->wrap( $f );

   ok( defined $future, 'Future->wrap(Future) defined' );
   isa_ok( $future, "Future", 'Future->wrap(Future)' );

   $f->done( "Wrapped Future" );
   is( scalar $future->result, "Wrapped Future", 'Future->wrap(Future)->result' );

   $future = Future->wrap( "Plain string" );

   ok( defined $future, 'Future->wrap(string) defined' );
   isa_ok( $future, "Future", 'Future->wrap(string)' );

   is( scalar $future->result, "Plain string", 'Future->wrap(string)->result' );
}

# unwrap
{
   is_deeply( [ Future->unwrap( Future->done( 1, 2, 3 ) ) ],
              [ 1, 2, 3 ],
              'Future->unwrap Future in list context' );
   is_deeply( [ Future->unwrap( 1, 2, 3 ) ],
              [ 1, 2, 3 ],
              'Future->unwrap plain list in list context' );

   is( scalar Future->unwrap( Future->done( qw( a b c ) ) ),
       "a",
       'Future->unwrap Future in scalar context' );
   is( scalar Future->unwrap( qw( a b c ) ),
       "a",
       'Future->unwrap plain list in scalar context' );
}

done_testing;
