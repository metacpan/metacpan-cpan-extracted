#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future;

use Future::AsyncAwait;

# immediate done ANON scalar
{
   my $want;

   my $func = async sub {
      $want = wantarray         ? "list" :
              defined wantarray ? "scalar" : "void";
      return 5;
   };

   my $f = $func->();

   isa_ok( $f, [ "Future" ], '$f' );

   is( $want, "list", 'func saw list context' );

   ok( $f->is_ready, '$f is immediate' );
   is( scalar $f->get, 5, '$f->get' );
}

# immediate done named scalar
{
   async sub func_10 {
      return 10;
   };

   my $f = func_10();

   isa_ok( $f, [ "Future" ], '$f' );

   ok( $f->is_ready, '$f is immediate' );
   is( scalar $f->get, 10, '$f->get' );
}

# immediate done list
{
   async sub func_list {
      return 1 .. 5
   };

   my $f = func_list();

   isa_ok( $f, [ "Future" ], '$f' );

   ok( $f->is_ready, '$f is immediate' );
   is( [ $f->get ], [ 1 .. 5 ], '$f->get' );
}

# immediate fail
{
   async sub func_die
   {
      die "Failure\n";
   }

   my $f = func_die();

   isa_ok( $f, [ "Future" ], '$f' );

   ok( $f->is_ready, '$f is immediate' );
   is( scalar $f->failure, "Failure\n", '$f->failure' );
}

# immediate done list in list context
{
   my @ret = (async sub { return 1, 2, 3 })->( 4, 5, 6 );

   is( scalar @ret, 1, 'async sub returns 1 value in list context' ) or
      diag( "async sub returned <@ret>" );
   isa_ok( shift @ret, [ "Future" ], 'Single result was a Future' );
}

# async sub can be declared in another package
{
   async sub Some::Other::Package::asub { return 123; }

   ok( defined Some::Other::Package->can( "asub" ),
      'async sub can be declared in another package' );

   is( Some::Other::Package::asub->get, 123,
      'async sub in another package runs OK' );
}

# unimport
{
   no Future::AsyncAwait;

   sub async { return "normal function" }

   is( async, "normal function", 'async() parses as a normal function call' );
}

# (related to) RT151046
{
   async sub forward_decl;
   pass( 'Forward declaration of a sub permits async keyword' );
}

done_testing;
