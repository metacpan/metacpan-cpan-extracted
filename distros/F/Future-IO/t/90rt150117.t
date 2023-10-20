#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::ExpectAndCheck 0.06; # ->will_return_using can modify caller args

use Errno qw( EAGAIN );

# We need to ensure we have a pureperl Future implementation for the following
# helper function to work properly
BEGIN { $ENV{PERL_FUTURE_NO_XS} = 1; }

use Future;
use Future::IO;

BEGIN { Future->isa( "Future::PP" ) or
   plan skip_all => "Unable to ensure that Future uses the pure-perl implementation"; }

sub get_future_oncancel
{
   my ( $f ) = @_;
   # gut-wrenching into Future
   my $on_cancel = $f->{on_cancel} or return;
   return grep { defined } @$on_cancel;
}

sub count_future_dependents
{
   my ( $f ) = @_;

   my $count = 0;

   my @queue = ( $f );
   while( @queue ) {
      my $f = shift @queue;
      $count++;
      push @queue, get_future_oncancel $f;
   }

   return $count;
}

my ( $controller, $puppet ) = Test::ExpectAndCheck->create;

# ->sysread does not build long future chains on EAGAIN
{
   my $read_f;

   my $dep_count;

   # 100 times yield undef/EAGAIN
   for( 1 .. 100 ) {
      $controller->expect( blocking => 1 )
         ->will_return( 1 );
      $controller->expect( sysread => Test::Deep::ignore(), 128 )
         ->will_return_using( sub { $! = EAGAIN; return undef } );
   }

   $controller->expect( blocking => 1 )
      ->will_return( 1 );
   $controller->expect( sysread => Test::Deep::ignore(), 128 )
      ->will_return_using( sub {
         my ( $args ) = @_;
         $args->[0] = "result";

         $dep_count = count_future_dependents $read_f;

         return length $args->[0];
      });

   $read_f = Future::IO->sysread( $puppet, 128 );
   is( $read_f->get, "result", '->sysread yields result' );

   is( $dep_count, 1, '->sysread future did not build a big dependent chain' );

   $controller->check_and_clear( '->sysread' );
}

done_testing;
