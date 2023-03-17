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

use Future::AsyncAwait qw( :experimental(cancel) );

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

sub precancelled
{
   my $f1 = Future->new;
   my $fret = (async sub {
      CANCEL { }
      await $f1;
   })->();
   $f1->done;
   $fret->get;
}

no_growth \&precancelled,
   calls => 10000,
   'precancellation does not grow memory';

# RT142222
{
   my $ftick;

   my $floop = (async sub {
      while(1) {
         await ( $ftick = Future->new );
      }
   })->();

   no_growth sub {
      my $f = $ftick;
      undef $ftick;
      $f->done;
   }, calls => 10000,
      'loop later does not grow memory';
}

done_testing;
