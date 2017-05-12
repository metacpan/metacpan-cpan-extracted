#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;
use IO::Async::Loop;

use Socket qw( getnameinfo inet_aton pack_sockaddr_in );

use IO::Async::Resolver::LibAsyncNS;

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

my $resolver = IO::Async::Resolver::LibAsyncNS->new;

$loop->add( $resolver );

no warnings 'redefine';
*IO::Async::Function::call = sub {
   fail( "IO::Async::Function->call was invoked" );
};

# getnameinfo 127.0.0.1 AF_INET
SKIP: {
   skip "127.0.0.1 does not appear to have a name", 1 unless
      !( getnameinfo( pack_sockaddr_in(0, inet_aton("127.0.0.1")), 0 ) )[0];

   my $f = $resolver->getnameinfo(
      addr => pack_sockaddr_in( 0, inet_aton( "127.0.0.1" ) ),
   );

   ok( !$f->is_ready, '$f not yet ready before await' );

   wait_for { $f->is_ready };

   ok( $f->is_done, '$f completes successfully' );

   my ( $host ) = $f->get;
   ok( defined $host, '$f yields a hostname' );
}

$loop->remove( $resolver );

done_testing;
