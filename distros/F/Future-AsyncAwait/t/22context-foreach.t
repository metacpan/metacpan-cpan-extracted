#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

# foreach(ARRAY) await
{
   my @F = map { Future->new } 1 .. 3;

   async sub with_foreach_array
   {
      foreach my $f ( @F ) {
         defined $f or die "ARGH: expected a Future";
         await $f;
      }
      return "end foreach";
   }

   my $fret = with_foreach_array();

   $F[0]->done;
   $F[1]->done;
   $F[2]->done;

   is( scalar $fret->get, "end foreach", '$fret now ready after foreach(ARRAY) loop' );
}

# foreach(LIST) await
{
   my @F = map { Future->new } 1 .. 3;

   async sub with_foreach_list
   {
      foreach my $f ( $F[0], $F[1], $F[2] ) {
         defined $f or die "ARGH: expected a Future";
         await $f;
      }
      return "end foreach";
   }

   my $fret = with_foreach_list();

   $F[0]->done;
   $F[1]->done;
   $F[2]->done;

   is( scalar $fret->get, "end foreach", '$fret now ready after foreach(LIST) loop' );
}

# foreach(LAZY IV) await
{
   my @F = map { Future->new } 1 .. 3;

   async sub with_foreach_lazy_iv
   {
      foreach my $idx ( 0 .. 2 ) {
         defined $idx or die "ARGH: Expected an integer index";
         await $F[$idx];
      }
      return "end foreach";
   }

   my $fret = with_foreach_lazy_iv();

   $F[0]->done;
   $F[1]->done;
   $F[2]->done;

   is( scalar $fret->get, "end foreach", '$fret now ready after foreach(LAZY IV) loop' );
}

# foreach(LAZY SV) await
{
   my %F = map { $_ => Future->new } 'a' .. 'c';

   async sub with_foreach_lazy_sv
   {
      foreach my $key ( 'a' .. 'c' ) {
         defined $key or die "ARGH: Expected a string key";
         await $F{$key};
      }
      return "end foreach";
   }

   my $fret = with_foreach_lazy_sv();

   $F{a}->done;
   $F{b}->done;
   $F{c}->done;

   is( scalar $fret->get, "end foreach", '$fret now ready after foreach(LAZY SV) loop' );
}

# RT#124144
{
   my $f1 = Future->new;
   my $f2 = Future->new;

   async sub with_foreach_await_twice
   {
      foreach my $x ( 0 ) {
         await $f1;
         await $f2;
      }
      return "awaited twice";
   }

   my $fret = with_foreach_await_twice();

   $f1->done;
   $f2->done;

   is( scalar $fret->get, "awaited twice", '$fret now ready after foreach with two awaits' );
}

# TODO:
#   This ought to be a compiletime check. That's hard right now so for now
#   it's a runtime check
{
   our $VAR;

   my $f1 = Future->new;

   async sub foreach_pkgvar
   {
      foreach $VAR ( 1 .. 3 ) {
         await $f1;
      }
   }

   my $fret = foreach_pkgvar();
   $f1->done;

   ok( $fret->failure, 'foreach $VAR failed' );
   like( $fret->failure, qr/\bnon-lexical iterator\b/,
      'Failure message refers to non-lexical iterator' );
}

done_testing;
