#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN { plan skip_all => "This test requires perl 5.35.5" unless $] >= 5.035005 }

use experimental 'for_list';

use Future;

use Future::AsyncAwait;

# foreach(ARRAY) await
{
   my @idxF = map { $_ => Future->new } 1 .. 3;
   my @result;

   async sub with_foreach_list_array
   {
      foreach my ( $idx, $f ) ( @idxF ) {
         defined $f or die "ARGH: expected a Future at idx $idx";
         await $f;
         push @result, ( $idx, $f );
      }
      return "end foreach";
   }

   my $fret = with_foreach_list_array();

   $idxF[1]->done;
   $idxF[3]->done;
   $idxF[5]->done;

   is( scalar $fret->get, "end foreach", '$fret now ready after foreach(ARRAY) loop' );
   is( \@result, \@idxF, '@result after foreach(ARRAY) loop' );
}

# foreach(LIST) await
{
   my @F = map { Future->new } 1 .. 3;
   my @result;

   async sub with_foreach_list_list
   {
      foreach my ( $idx, $f ) ( 0 => $F[0], 1 => $F[1], 2 => $F[2] ) {
         defined $f or die "ARGH: expected a Future at idx $idx";
         await $f;
         push @result, ( $idx, $f );
      }
      return "end foreach";
   }

   my $fret = with_foreach_list_list();

   $F[0]->done;
   $F[1]->done;
   $F[2]->done;

   is( scalar $fret->get, "end foreach", '$fret now ready after foreach(LIST) loop' );
   is( \@result, [ 0 => $F[0], 1, => $F[1], 2 => $F[2] ], '@result after foreach(LIST) loop' );
}

done_testing;
