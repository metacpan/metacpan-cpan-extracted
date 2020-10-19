#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Identity;

use Future;
use Future::Utils qw( call );

# call returns future
{
   my $ret_f;
   my $f = call {
      return $ret_f = Future->new;
   };

   identical( $f, $ret_f, 'call() returns future returned from its code' );
   $f->cancel;
}

# call returns immediate failure on die
{
   my $f = call {
      die "argh!\n";
   };

   ok( $f->is_ready, 'call() returns immediate future on die' );
   is( scalar $f->failure, "argh!\n", 'failure from immediate future on die' );
}

# call returns immediate failure on non-Future return
{
   my $f = call {
      return "non-future";
   };

   ok( $f->is_ready, 'call() returns immediate future on non-future return' );
   like( scalar $f->failure, qr/^Expected __ANON__.*\(\S+ line \d+\) to return a Future$/,
      'failure from immediate future on non-future return' );
}

done_testing;
