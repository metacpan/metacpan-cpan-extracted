use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Future;

# ->get on immediate done
{
   my $f = Future->done( result => "here" );

   is_deeply( [ $f->get ], [ result => "here" ], 'Result of ->get on done future' );
}

# ->get on immediate fail
{
   my $f = Future->fail( "Something broke" );

   like( exception { $f->get }, qr/^Something broke at /, 'Exception from ->get on failed future' );
}

# ->get on cancelled
{
   my $f = Future->new;
   $f->cancel;

   like( exception { $f->get }, qr/cancelled/, 'Exception from ->get on cancelled future' );
}

# ->get while pending without await
{
   my $f = Future->new;

   like( exception { $f->get }, qr/ is not yet complete /, 'Exception from ->get on pending future' );
}

# ->get invokes ->await
{
   no strict 'refs';
   no warnings 'redefine';
   local *{"Future::await"} = sub {
      shift->done( "result of await" );
   };

   my $f = Future->new;

   is( scalar $f->get, "result of await", 'Result of ->get with overloaded ->await' );
}

# ->failure invokes ->await
{
   no strict 'refs';
   no warnings 'redefine';
   local *{"Future::await"} = sub {
      shift->fail( "Oopsie\n" );
   };

   my $f = Future->new;

   is( scalar $f->failure, "Oopsie\n", 'Result of ->failure with overloaded ->await' );
}

# ->await on already-complete future succeeds
{
   my $e;

   ok( !( $e = exception { Future->done( "Result" )->await } ),
      '->await on done does not throw' ) or
      diag( "Exception was: $e" );

   ok( !( $e = exception { Future->fail( "Oops\n" )->await } ),
      '->await on done does not throw' ) or
      diag( "Exception was: $e" );
}

done_testing;
