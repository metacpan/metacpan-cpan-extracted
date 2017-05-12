#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;
use IO::Async::Loop;

use IO::Async::Resolver::DNS;

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

my $resolver = $loop->resolver;

{
   can_ok( $resolver, "res_query" );

   my $result;
   $resolver->res_query(
      dname => "www.cpan.org",
      type  => "A",
      on_resolved => sub {
         $result = shift;
      },
      on_error => sub { die "Test failed early - $_[-1]" },
   );

   wait_for { $result };

   isa_ok( $result, "Net::DNS::Packet", '$result from ->res_query isa Net::DNS::Packet' );
   # Lets not be too sensitive to what the answers actually are
   cmp_ok( scalar $result->answer, '>=', 1, '$result from ->res_query contains some answers' ) or
      diag( $result->string );
}

{
   can_ok( $resolver, "res_search" );

   my $result;
   $resolver->res_search(
      dname => "www.cpan.org",
      type  => "A",
      on_resolved => sub {
         $result = shift;
      },
      on_error => sub { die "Test failed early - $_[-1]" },
   );

   wait_for { $result };

   isa_ok( $result, "Net::DNS::Packet", '$result from ->res_search isa Net::DNS::Packet' );
   # Lets not be too sensitive to what the answers actually are
   cmp_ok( scalar $result->answer, '>=', 1, '$result from ->res_search contains some answers' ) or
      diag( $result->string );
}

done_testing;
