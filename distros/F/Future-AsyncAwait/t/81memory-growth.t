#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN {
   eval { require Test::MemoryGrowth; } or
      plan skip_all => "No Test::MemoryGrowth";
}
use Test::MemoryGrowth;
use Test::Refcount;

use Future;

use Future::AsyncAwait;

async sub identity
{
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

sub abandoned
{
   my $f1 = Future->new;
   my $fret = (async sub {
      local $@;
      foreach my $i ( 1, 2, 3 ) {
         await $f1;
      }
   })->();
   undef $fret;
   undef $f1;
}

no_growth \&abandoned,
   calls => 10000,
   'abandoned async sub does not grow memory';

done_testing;
