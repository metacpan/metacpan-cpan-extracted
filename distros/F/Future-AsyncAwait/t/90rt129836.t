#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future::AsyncAwait;

async sub outer {
   my $inner = async sub {
      return "inner";
   };

   return await $inner->();
}

is( outer()->get, "inner", 'result of anon inside named' );

done_testing;
