#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;

async sub identity
{
   await $_[0];
}

# invoking async/await entirely from within a string eval
{
   ok eval q{
      my $f1 = Future->new;
      my $f2 = identity( $f1 );
      $f1->done( 1 );
      $f2->get;
   }, 'async/await from within string eval';
}

# await at string-eval level should be forbidden (RT126035)
{
   my $ok;
   my $e;

   (async sub {
      $ok = !eval q{await $_[0]};
      $e = $@;
   })->();

   ok( $ok, 'await in string eval fails to compile' );
   $ok and like( $e, qr/^await is not allowed inside string eval /, '' );
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;
