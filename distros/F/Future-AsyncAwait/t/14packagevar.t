#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

# single scalar
{
   our $VAR = "some variable";

   async sub with_pkgvar
   {
      my $copy = "VAR is $VAR";

      await $_[0];

      return "<$VAR>";
   }

   my $f1 = Future->new;
   my $fret = with_pkgvar( $f1 );

   $f1->done;

   is( scalar $fret->get, "<some variable>", '$fret now ready after done' );
}

done_testing;
