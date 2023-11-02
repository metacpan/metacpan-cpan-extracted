#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Future;
use Future::Selector;

# generators
{
   my $selector = Future::Selector->new;

   my $next_f;
   $selector->add(
      data => "generator",
      gen  => sub { $next_f = Future->new },
   );

   my $wait_f;

   $wait_f = $selector->select;
   ok( !$wait_f->is_ready, '->select remains pending initially' );
   ok( $next_f, 'generator called initially' );

   (do { my $f = $next_f; undef $next_f; $f })->done;

   ok( $wait_f->is_ready, '->select ready after generated f done' );
   is( [ $wait_f->get ], [ "generator", check_isa('Future') ],
      'await $f' );

   $wait_f = $selector->select;

   ok( $next_f, 'generator called again' );

   $next_f->done;

   ok( $wait_f->is_ready, '->select ready after generated f done again' );
   is( [ $wait_f->get ], [ "generator", check_isa('Future') ],
      'await $f again' );
}

# immediates don't tightloop
{
   my $selector = Future::Selector->new;

   my @next_f;
   $selector->add(
      data => "generator",
      gen  => sub {
         return if @next_f > 100; # avoid infinite crash
         push @next_f, Future->done( "OK" );
         return $next_f[-1];
      },
   );

   # One gets created initially by ->add
   is( scalar @next_f, 1, 'only one gen created' );

   my $wait_f;

   $wait_f = $selector->select;

   ok( $wait_f->is_ready, '->select immediately ready' );
   is( scalar @next_f, 2, 'only two gen created' );

   $wait_f = $selector->select;

   is( scalar @next_f, 3, 'only three gen created' );
}

done_testing;
