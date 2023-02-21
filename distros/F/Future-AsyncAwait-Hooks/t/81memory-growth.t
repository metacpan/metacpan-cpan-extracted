#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   eval { require Test::MemoryGrowth; } or
      plan skip_all => "No Test::MemoryGrowth";
}
use Test::MemoryGrowth;

use Future;
use Future::AsyncAwait;
use Future::AsyncAwait::Hooks;

async sub identity
{
   my @arr;
   suspend { push @arr, 1; }
   resume  { push @arr, 2; }

   await $_[0];
}

sub code
{
   my $f1 = Future->new;
   my $fret = identity( $f1 );
   $f1->done;
   $fret->get;
}

no_growth \&code,
   calls   => 10000,
   'async/await does not grow memory';

done_testing;
