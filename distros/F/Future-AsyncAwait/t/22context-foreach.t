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

# RT#129215
{
   my @F = map { Future->new } 0, 1, 2;
   my $fret = (async sub {
      foreach my $idx ( 0, 1, 2 ) {
         await $F[$idx];
      }
      return "OK";
   })->();

   # Arrange for the stack to be at different heights on each resume
   my $tmp = do { 1 + ( $F[0]->done // 0 ) };
   $tmp = [ 2, 3, [ $F[1]->done ] ];
   $tmp = 4 * ( 6 + ( $F[2]->done // 0 ) );

   is( scalar $fret->get, "OK", '$fret now ready after differing stack resumes' );
}

# RT#129319 - foreach(LIST) with extra values
{
   my @F = map { Future->new } 0, 1, 2;
   my $fret = (async sub {
      my $ret = "";
      foreach my $idx ( 0, 1, 2 ) {
         # $ret will appear on the stack after the foreach-LIST items
         $ret .= await $F[$idx];
      }
      return $ret;
   })->();

   $F[0]->done( "A" );
   $F[1]->done( "B" );
   $F[2]->done( "C" );

   is( scalar $fret->get, "ABC", '$fret now ready after await with stack items before LIST' );
}

# RT#129319 - foreach(LIST) with extra marks
{
   my @F = map { Future->new } 0, 1, 2;
   my $fret = (async sub {
      my @values;
      foreach my $idx ( 0, 1, 2 ) {
         # push list creates an extra mark
         push @values, "(", await $F[$idx], ")";
      }
      return join "", @values;
   })->();

   $F[0]->done( "A" );
   $F[1]->done( "B" );
   $F[2]->done( "C" );

   is( scalar $fret->get, "(A)(B)(C)", '$fret now ready after await with stack marks before LIST' );
}

SKIP: {
   skip "IO::Async::Loop not available", 1 unless eval { require IO::Async::Loop; };
   my $loop = IO::Async::Loop->new;

   my $out = "";

   (async sub {
      foreach my $k (qw( one two three four )) {
         $out .= "$k\n";
         await $loop->delay_future(after => 0.01);
         $out .= "$k\n";
      }
   })->()->get;

   is( $out, "one\none\ntwo\ntwo\nthree\nthree\nfour\nfour\n",
      'Output from sleepy foreach(LIST)'
   );
}

{
   our $VAR;

   my $ok = !eval q{
      async sub foreach_pkgvar
      {
         foreach $VAR ( 1 .. 3 ) {
            await $f1;
         }
      }
   };
   my $e = $@;

   ok( $ok, 'await in non-lexical foreach loop fails to compile' );
   $ok and like( $e, qr/^await is not allowed inside foreach on non-lexical iterator variable /, '' );
}

done_testing;
