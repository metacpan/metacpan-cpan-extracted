#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Future;
use Future::Selector;

# awaited failure
{
   my $selector = Future::Selector->new;

   $selector->add(
      data => "red",
      f    => my $fred = Future->new,
   );
   $selector->add(
      data => "blue",
      f    => my $fblue = Future->new,
   );

   my $f;

   $f = $selector->select;
   ok( !$f->is_ready, '->select remains pending initially' );

   $fred->fail( "Red Failure\n" );

   ok( $f->is_failed, '$f failed after one failed' );
   is( [ $f->failure ], [ "Red Failure\n" ],
      'await $f fails' );

   $f = $selector->select;
   ok( !$f->is_ready, '->select can go again' );

   $fblue->done( "Blue Result" );

   ok( $f->is_ready, '$f ready after two done' );
   is( [ $f->get ], [ "blue", exact_ref( $fblue ) ],
      'await $f again' );

   like( dies { $selector->select }, qr/ cowardly refuses to sit idle and do nothing at /,
      '->select a third time fails when empty' );
}

# immediate failure
{
   my $selector = Future::Selector->new;

   $selector->add(
      data => "red",
      f    => my $fred = Future->fail( "Already failed\n" ),
   );
   $selector->add(
      data => "blue",
      f    => my $fblue = Future->new,
   );

   my $f;

   $f = $selector->select;

   ok( $f->is_failed, '$f failed immediately' );
   is( [ $f->failure ], [ "Already failed\n" ],
      'await $f fails' );
}

done_testing;
