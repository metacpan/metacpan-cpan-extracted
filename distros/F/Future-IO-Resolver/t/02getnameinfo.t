#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

use Future::IO;
use Future::IO::Resolver;

use Socket qw( pack_sockaddr_in inet_aton );

Future::IO->load_best_impl;

# getnameinfo 127.0.0.1 AF_INET
{
   my $f = Future::IO::Resolver->getnameinfo(
      addr => pack_sockaddr_in( 0, inet_aton( "127.0.0.1" ) ),
   );

   my ( $host ) = $f->get;
   ok( defined $host, 'getnameinfo yields a result' );
   # Since we got *a* result, we'll not further inspect the inner details, as
   # that just makes a fragile test that often fails on weirdly set up machines
}

done_testing;
