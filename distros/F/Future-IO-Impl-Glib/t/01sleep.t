#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Time::HiRes qw( time );

use Future::IO;
use Future::IO::Impl::Glib;

sub time_about(&@)
{
   my ( $code, $want_time, $name ) = @_;
   my $test = Test::Builder->new;

   my $t0 = time();
   $code->();
   my $t1 = time();

   my $got_time = $t1 - $t0;
   $test->ok(
      $got_time >= $want_time * 0.9 && $got_time <= $want_time * 1.5, $name
   ) or
      $test->diag( sprintf "Test took %.3f seconds", $got_time );
}

time_about sub {
   Future::IO->sleep( 0.2 )->get;
}, 0.2, 'Future::IO->sleep( 0.2 ) sleeps 0.2 seconds';

time_about sub {
   my $f1 = Future::IO->sleep( 0.1 );
   my $f2 = Future::IO->sleep( 0.3 );
   $f1->cancel;
   $f2->get;
}, 0.3, 'Future::IO->sleep can be cancelled';

{
   my $f1 = Future::IO->sleep( 0.1 );
   my $f2 = Future::IO->sleep( 0.3 );

   is( $f2->await, $f2, '->await returns Future' );
   ok( $f2->is_ready, '$f2 is ready after ->await' );
   ok( $f1->is_ready, '$f1 is also ready after ->await' );
}

done_testing;
