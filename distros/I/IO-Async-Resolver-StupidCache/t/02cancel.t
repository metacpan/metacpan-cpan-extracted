#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;
use IO::Async::Loop;

use Future;

use IO::Async::Resolver::StupidCache;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my $next_f;
{
   package MockResolver;

   sub new { bless {}, shift }
   sub resolve { return $next_f = Future->new }
}

my $resolver = IO::Async::Resolver::StupidCache->new(
   source => MockResolver->new,
);

$loop->add( $resolver );

my ( $fA, $fB ) = map {
   $resolver->resolve( type => "getaddrinfo_hash", data => [ service => 0, host => "localhost" ] )
} 1 .. 2;

ok( $next_f, '$next_f now set for concurrent resolve' );

$fA->cancel;

$next_f->done( "", [ "result" ] );

ok( $fB->is_ready, '$fB is ready' );
is_deeply( [ $fB->get ], [ '', [ "result" ] ], ,'$fB result' );

done_testing;
