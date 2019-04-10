#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Time::HiRes qw( time );

use Future::IO;

sub time_about(&@)
{
   my ( $code, $want_time, $name ) = @_;
   my $test = Test::Builder->new;

   my $t0 = time();
   $code->();
   my $t1 = time();

   my $got_time = $t1 - $t0;
   $test->ok(
      $got_time >= $want_time * 0.9 && $got_time <= $want_time * 1.1, $name
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

done_testing;
