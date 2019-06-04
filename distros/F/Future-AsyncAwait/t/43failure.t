#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

async sub identity
{
   return await $_[0];
}

# die in async is transparent to thrown objects
{
   my $fret = (async sub {
      die bless [qw( a b c )], "TestException";
   })->();

   ok( $fret->is_failed, '$fret failed after die in async' );
   is( ref $fret->failure, "TestException", 'die in async preserves object' );
   is_deeply( [ @{ $fret->failure } ], [qw( a b c )],
      'die in async preserves object contents' );
}

# await is transparent to thrown objects
{
   my $f1 = Future->new;
   my $fret = (async sub {
      eval { await $f1 } or return $@;
   })->();

   $f1->fail( bless [qw( d e f )], "TestException" );

   is( ref $fret->get, "TestException", 'await failure preserves object' );
   is_deeply( [ @{ $fret->get } ], [qw( d e f )],
      'await failure preserves object contents' );
}

# async/await is transparent to thrown objects
{
   my $f1 = Future->new;
   my $fret = identity( $f1 );

   $f1->fail( bless [qw( g h i )], "TestException" );

   ok( $fret->is_failed, '$fret failed after die in async/await' );
   is( ref $fret->failure, "TestException", 'die in async/await preserves object' );
   is_deeply( [ @{ $fret->failure } ], [qw( g h i )],
      'die in async/await preserves object contents' );
}

# async/await is transparent to failures
SKIP: {
   skip "This test requires Future version 0.40", 1 unless $Future::VERSION >= 0.40;
   my $f1 = Future->new;
   my $fret = identity( $f1 );

   $f1->fail( "message\n", category => qw( details here ) );
   ok( $fret->is_failed, '$fret failed after ->fail' );
   is_deeply( [ $fret->failure ],
      [ "message\n", category => qw( details here ) ],
      '$fret->failure after ->fail' );
}

done_testing;
