#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0 0.000148; # is_oneref

use Scalar::Util qw( reftype );

use Future;

use Future::AsyncAwait;

{
   async sub identity
   {
      await $_[0];
   }

   my $f1 = Future->new;
   my $fret = identity( $f1 );

   # At this point we want to grab the generated CV that's now been pushed as
   # a callback of $f1.
   # This code is probably going to be very fragile, so we'll silently skip it
   # if it fails to work
   my $generated_cv;
   if( reftype $f1 eq "HASH" and
       $f1->{callbacks} and @{ $f1->{callbacks} } and
       $f1->{callbacks}[0] and
       ref $f1->{callbacks}[0][1] eq "CODE" ) {
      $generated_cv = $f1->{callbacks}[0][1];
   }

   my $destroyed;
   sub Destructor::DESTROY { $destroyed++ }

   $f1->done( bless [], "Destructor" );

   is_oneref( $f1, '$f1 should have one ref' );

   undef $f1;

   ok( !$destroyed, 'Not destroyed before $fret->get' );

   $fret->get;
   ok( !$destroyed, 'Not destroyed after $fret->get' );

   is_oneref( $fret, '$fret should have one ref' );

   undef $fret;
   ok( $destroyed, 'Destroyed by dropping $fret' );

   $generated_cv and
      is_oneref( $generated_cv, '$generated_cv should have one ref' );

   undef $generated_cv;
}

done_testing;
