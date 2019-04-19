#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;

# ->cancel stops execution
{
   my $called;

   my $f1 = Future->new;
   my $f2 = (async sub {
      await $f1;
      $called++;
   })->();

   $f2->cancel;
   $f1->done;

   ok( !$called, 'async sub stops execution after ->cancel' );
}

# ->cancel propagates
SKIP: {
   # See
   #   https://rt.cpan.org/Ticket/Display.html?id=129202#txn-1843918
   skip "Cancel propagation is not implemented before perl 5.24", 1
      if $] < 5.024;

   my $f1 = Future->new;
   my $f2 = (async sub { await $f1 })->();

   $f2->cancel;

   ok( $f1->is_cancelled, 'async sub propagates cancel' );
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;
