#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future;
use Future::AsyncAwait;

my $f1 = Future->new;

async sub func { await $f1 }

# RT126036
END {
   my $f2 = func();
   $f1->done( 1 );

   ok scalar $f2->get, "async/await works at END time";

   done_testing;
}
