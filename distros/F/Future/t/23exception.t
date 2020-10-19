#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Future;

# ->result throws an object
{
   my $f = Future->fail( "message\n", category => qw( a b ) );
   my $e = exception { $f->result };

   # TODO: some sort of predicate test function to check this
   is( $e->message,  "message\n", '$e->message from exceptional get' );
   is( $e->category, "category",  '$e->category from exceptional get' );
   is_deeply( [ $e->details ], [qw( a b )], '$e->details from exceptional get' );

   # Still stringifies OK
   is( "$e", "message\n", '$e stringifies properly' );

   my $f2 = $e->as_future;
   is_deeply( [ $f2->failure ],
      [ "message\n", category => qw( a b ) ],
      '$e->as_future returns a failed Future' );
}

# ->fail can accept an exception object
{
   my $e = Future::Exception->from_future(
      Future->fail( "message\n", category => qw( c d ) )
   );
   my $f = Future->fail( $e );

   is_deeply( [ $f->failure ], [ "message\n", category => qw( c d ) ],
      '->failure from Future->fail on wrapped exception' );
}

# ->call can rethrow the same
{
   my $f1 = Future->fail( "message\n", category => qw( e f ) );
   my $f2 = Future->call( sub {
      $f1->result;
   });

   ok( $f2->is_failed, '$f2 failed' );
   is_deeply( [ $f2->failure ], [ "message\n", category => qw( e f ) ],
      '->failure from Future->call on rethrown failure' );
}

# Future::Exception->throw
{
   my $e = exception { Future::Exception->throw( "message\n", category => qw( g h ) ) };

   is( $e->message,  "message\n", '$e->message from F::E->throw' );
   is( $e->category, "category",  '$e->category from F::E->throw' );
   is_deeply( [ $e->details ], [qw( g h )], '$e->details from F::E->throw' );

   $e = exception { Future::Exception->throw( "short", category => ) };
   like( $e->message, qr/^short at \S+ line \d+\.$/, 'F::E->throw appends file/line' );
}

done_testing;
