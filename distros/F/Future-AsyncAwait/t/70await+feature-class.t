#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0 0.000148; # is_oneref

BEGIN {
   plan skip_all => "Future >= 0.49 is not available"
      unless eval { require Future;
                    Future->VERSION( '0.49' ) };
   plan skip_all => "Future::AsyncAwait >= 0.45 is not available"
      unless eval { require Future::AsyncAwait;
                    Future::AsyncAwait->VERSION( '0.45' ) };
   # version 5.37.10 added the ability to start_subparse() with CVf_IsMETHOD,
   # which we need
   plan skip_all => "feature 'class' is not available"
      unless $^V ge v5.37.10;
   plan skip_all => "XS::Parse::Sublike >= 0.17 is not in use"
      unless $XS::Parse::Sublike::VERSION >= 0.17;

   # If Future::XS is installed, then check it's at least 0.08; earlier
   # versions will crash
   if( eval { require Future::XS } ) {
      plan skip_all => "Future::XS is installed but it is older than 0.08"
         unless eval { Future::AsyncAwait->VERSION( '0.08' ); };
   }

   diag( "Future::AsyncAwait $Future::AsyncAwait::VERSION, " .
         "core perl version $^V" );
}

use Future::AsyncAwait;

use feature 'class';
no warnings 'experimental::class';

# async method
{
   class Thunker {
      field $_times_thunked = 0;

      method count { $_times_thunked }

      async method thunk {
         my ( $f ) = @_;
         await $f;
         $_times_thunked++;
         return "result";
      }
   }

   my $thunker = Thunker->new;
   is_oneref( $thunker, 'after ->new' );

   my $f1 = Future->new;
   my $fret = $thunker->thunk( $f1 );
   is_refcount( $thunker, 2, 'during async sub' );

   is( $thunker->count, 0, 'count is 0 before $f1->done' );

   $f1->done;

   is_oneref( $thunker, 'after ->done' );

   is( $thunker->count, 1, 'count is 1 after $f1->done' );
   is( $fret->get, "result", '$fret for await in async method' );
}

done_testing;
