#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;

my $before;
my $after;

async sub identity
{
   await $_[0];
}

# scalar
{
   my $f1 = Future->new;
   my $fret = identity( $f1 );

   isa_ok( $fret, "Future", 'identity() returns a Future' ) and do {
      ok( !$fret->is_ready, '$fret is not immediate for pending scalar' );
   };

   $f1->done( "result" );
   is( scalar $fret->get, "result", '$fret->get for scalar' );
}

# list
{
   my $f1 = Future->new;
   my $fret = identity( $f1 );

   isa_ok( $fret, "Future", 'identity() returns a Future' );

   $f1->done( list => "goes", "here" );
   is_deeply( [ $fret->get ], [qw( list goes here )], '$fret->get for list' );
}

async sub makelist
{
   1, 2, [ 3, await $_[0], 6 ], 7, 8
}

# stack discipline test
{
   my $f1 = Future->new;
   my $fret = makelist( $f1 );

   $f1->done( 4, 5 );

   is_deeply( [ $fret->get ],
              [ 1, 2, [ 3, 4, 5, 6 ], 7, 8 ],
              'async/await respects stack discipline' );
}

# failure
{
   my $f1 = Future->new;
   my $fret = identity( $f1 );

   isa_ok( $fret, "Future", 'identity() returns a Future' );

   $f1->fail( "It failed\n" );

   is( $fret->failure, "It failed\n", '$fret->failure for fail' );
}

# die
{
   my $f1 = Future->new;
   async sub dies {
      await $f1;
      die "Oopsie\n";
   }

   my $fret = dies();
   $f1->done;

   is( $fret->failure, "Oopsie\n", '$fret->failure for dies' );
}

# ANON sub
{
   my $func = async sub {
      return await $_[0];
   };

   my $f1 = Future->new;
   my $fret = $func->( $f1 );

   ok( !$fret->is_ready, '$fret is not immediate for pending ANON' );

   $f1->done( "later" );
   is( scalar $fret->get, "later", '$fret->get for ANON' );
}

# ANON sub closure
{
   my $f1 = Future->new;

   my $func = async sub {
      return await $f1;
   };

   my $fret = $func->( $f1 );

   ok( !$fret->is_ready, '$fret is not immediate for pending ANON closure' );

   $f1->done( "later" );
   is( scalar $fret->get, "later", '$fret->get for ANON closure' );
}

# await in non-async sub is forbidden
{
   my $ok = !eval 'sub { await $_[0] }';
   my $e = $@;

   ok( $ok, 'await in non-async sub fails to compile' );
   $ok and like( $e, qr/Cannot 'await' outside of an 'async sub' at /, '' );
}

{
   my $ok = !eval 'async sub { my $c = sub { await $_[0] } }';

   ok( $ok, 'await in non-async sub inside async sub fails to compile' );
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;
