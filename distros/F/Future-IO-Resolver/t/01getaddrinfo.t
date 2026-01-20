#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

use Future::IO;
use Future::IO::Resolver;

use Socket qw( AF_INET SOCK_STREAM );

Future::IO->load_best_impl;

# getaddrinfo localhost/12345
{
   my $f = Future::IO::Resolver->getaddrinfo(
      host     => "localhost",
      service  => "12345",
      family   => AF_INET,
      socktype => SOCK_STREAM,
   );

   my @res = $f->get;

   cmp_ok( scalar @res, '>=', 1, 'getaddrinfo localhost/12345 yields at least 1 result' );

   is( $res[0]->{family},   AF_INET,     'first result family is AF_INET' );
   is( $res[0]->{socktype}, SOCK_STREAM, 'first result socktype is SOCK_STREAM' );
   ok( defined $res[0]->{addr},          'first result contains an addr' );
   # Since we got *a* result, we'll not further inspect the inner details, as
   # that just makes a fragile test that often fails on weirdly set up machines
}

# cancel
{
   my $f1 = Future::IO::Resolver->getaddrinfo(
      host    => "abcde.fghij",
      service => 0,
   );
   my $f2 = Future::IO::Resolver->getaddrinfo(
      host    => "localhost",
      service => "23456",
   );

   $f1->cancel;
   my @res = $f2->get;

   cmp_ok( scalar @res, '>=', 1, 'getaddrinfo yields result after previous cancelled' );
}

done_testing;
