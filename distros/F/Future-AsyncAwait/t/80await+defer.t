#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   plan skip_all => "Future is not available"
      unless eval { require Future };
   plan skip_all => "Future::AsyncAwait >= 0.50 is not available"
      unless eval { require Future::AsyncAwait;
                    Future::AsyncAwait->VERSION( '0.50' ) };
   plan skip_all => "Syntax::Keyword::Defer >= 0.02 is not available"
      unless eval { require Syntax::Keyword::Defer;
                    Syntax::Keyword::Defer->VERSION( '0.02' ) };

   Future::AsyncAwait->import;
   Syntax::Keyword::Defer->import;

   diag( "Future::AsyncAwait $Future::AsyncAwait::VERSION, " .
         "Syntax::Keyword::Defer $Syntax::Keyword::Defer::VERSION" );
}

# defer before await
{
   my $ok;

   my $f1 = Future->new;
   my $fret = (async sub {
      defer { $ok = "1" }
      await $f1;
      return "result";
   })->();

   ok( !defined $ok, '$ok not yet defined' );

   $f1->done;
   is( await $fret, "result", '$fret yields result' );

   is( $ok, "1", '$ok after ->done' );
}

# defer after await
{
   my $ok;

   my $f1 = Future->new;
   my $fret = (async sub {
      await $f1;
      defer { $ok = "2" }
      return "result";
   })->();

   ok( !defined $ok, '$ok not yet defined' );

   $f1->done;
   is( await $fret, "result", '$fret yields result' );

   is( $ok, "2", '$ok after ->done' );
}

# defer still runs for cancel (RT135351)
{
   my $ok;
   my $f1 = Future->new;
   my $fret = (async sub {
      defer { $ok++ }
      await $f1;
   })->();

   ok( !$ok, 'defer {} not run before ->cancel' );

   $fret->cancel;

   ok( $ok, 'defer {} was run after ->cancel' );
}

done_testing;
