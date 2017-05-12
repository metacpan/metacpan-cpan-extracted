#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;
use IO::Async::Loop;

use Socket qw( AF_INET SOCK_RAW getaddrinfo );

use IO::Async::Resolver::LibAsyncNS;

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

my $resolver = IO::Async::Resolver::LibAsyncNS->new;

$loop->add( $resolver );

no warnings 'redefine';
*IO::Async::Function::call = sub {
   fail( "IO::Async::Function->call was invoked" );
};

# getaddrinfo localhost IPv4
SKIP: {
   skip "localhost does not appear to have an IPv4 address", 1 unless
      !( getaddrinfo( "localhost", "", { family => AF_INET, socktype => SOCK_RAW } ) )[0];

   my $f = $resolver->getaddrinfo(
      host     => "localhost",
      family   => AF_INET,
      socktype => SOCK_RAW,
   );

   ok( !$f->is_ready, '$f not yet ready before await' );

   wait_for { $f->is_ready };

   ok( $f->is_done, '$f completes successfully' );

   my @res = $f->get;
   ok( scalar @res, '$f yields some results' );

   ok( defined $res[0]->{family}, 'First result has a family' );
}

$loop->remove( $resolver );

done_testing;
