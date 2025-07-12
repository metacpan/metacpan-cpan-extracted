#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Future;
use Future::Selector;

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

   $fred->cancel;

   ok( !$f->is_ready, '->select remains pending after red cancelled' );

   $fblue->done( "Blue Result" );

   ok( $f->is_ready, '->select now ready after blue done' );
   is( [ $f->get ], [ "blue", exact_ref( $fblue ) ],
      'await $f' );
}

# multiple concurrent run calls can't cross-cancel each other
{
   my $selector = Future::Selector->new;

   # create the main response runloop. it doesn't matter what it is, anything
   # will do
   my $run_f = $selector->run_until_ready(
      my $run_inner_f = Future->new->set_label( "run_inner_f" )
   )->set_label( "run_f" );

   ok( !$run_f->is_ready, 'Main run future initially pending' );

   my $request_f = $selector->run_until_ready(
      my $request_inner_f = Future->new->set_label( "request_inner_f" )
   )->set_label( "request_f" );

   ok( !$request_f->is_ready, 'Request future initially pending' );

   $request_f->cancel;
   ok( $request_inner_f->is_cancelled, 'Request inner future got cancelled' );

   ok( !$run_f->is_ready, 'Main run future still pending after cancelled request' )
      or $run_f->get;
   ok( !$run_inner_f->is_ready, 'Run loop inner future still pending after cancelled request' )
      or $run_inner_f->get;

   $run_f->cancel;
   $run_inner_f->cancel;
}

done_testing;
