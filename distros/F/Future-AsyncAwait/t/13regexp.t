#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

# Try to trigger SAVEt_FREEPV
{
   my $f1 = Future->new;
   my $fret = (async sub {
      my $bytes = "abcdefghijklmnopq";
      my $maxchunk = 6;
      my @chunks = $bytes =~ m/(.{1,$maxchunk})/gs;
      my $ret = "";

      await $f1;
      return scalar @chunks;
   })->();

   $f1->done;
   is( scalar $fret->get, 3, 'chunks' );
}

done_testing;
