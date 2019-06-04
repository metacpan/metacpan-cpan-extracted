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

# await over regexp (RT129321)
{
   my $f1 = Future->new;
   my $fret = (async sub {
      my $string = "Hello, world";
      $string =~ m/^(.*),/;

      await $f1;

      return $1, $-[1], $+[1];
   })->();

   $f1->done;
   is_deeply( [ $fret->get ], [ "Hello", 0, 5 ],
      'await restores regexp context' );
}

done_testing;
