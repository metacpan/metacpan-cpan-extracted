#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;

async sub identity
{
   return await $_[0];
}

async sub func
{
   my ( $f, @vals ) = @_;

   my $pad = "foo" . ref($f);
   my $x = 123;
   $x + 1 + [ "a", await identity $f ];
}

# unresolved
foreach ( 1 .. 1023 ) {
   my $f1 = Future->new;
   my $fret = func( $f1, 1, 2 );

   undef $fret;
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;
