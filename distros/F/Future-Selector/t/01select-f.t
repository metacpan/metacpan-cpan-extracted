#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Future;
use Future::Selector;

# awaited success
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

   $fred->done( "Red Result" );

   ok( $f->is_ready, '$f ready after one done' );
   is( [ $f->get ], [ "red", exact_ref( $fred ) ],
      'await $f' );

   $f = $selector->select;
   ok( !$f->is_ready, '->select can go again' );

   $fblue->done( "Blue Result" );

   ok( $f->is_ready, '$f ready after two done' );
   is( [ $f->get ], [ "blue", exact_ref( $fblue ) ],
      'await $f again' );

   like( dies { $selector->select }, qr/ cowardly refuses to sit idle and do nothing at /,
      '->select a third time fails when empty' );
}

# immediate success
{
   my $selector = Future::Selector->new;

   $selector->add(
      data => "red",
      f    => my $fred = Future->done( "Already ready" ),
   );
   $selector->add(
      data => "blue",
      f    => my $fblue = Future->new,
   );

   my $f;

   $f = $selector->select;

   ok( $f->is_ready, '$f ready immediately' );
   is( [ $f->get ], [ "red", exact_ref( $fred ) ],
      'await $f' );
}

# multiple success
{
   my $selector = Future::Selector->new;

   $selector->add(
      data => "red",
      f    => my $fred = Future->done( "Is Red" ),
   );
   $selector->add(
      data => "blue",
      f    => my $fblue = Future->done( "Is Blue" ),
   );

   my $f;

   $f = $selector->select;

   ok( $f->is_ready, '$f ready immediately' );
   is( [ $f->get ], [ "red", exact_ref( $fred ), "blue", exact_ref( $fblue ) ],
      'await $f' );
}

# ->select during completion of previous wait future
{
   my $selector = Future::Selector->new;

   $selector->add( data => "oneshot", f => my $f = Future->new );

   my $e;
   my $waitf1 = $selector->select->on_ready( sub {
      eval { $selector->select; 1 } or $e = $@;
   });

   $f->done;

   like( $e, qr/ cowardly refuses to sit idle and do nothing at /,
      'nested immediate ->select fails when empty' );
}

done_testing;
