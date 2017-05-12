#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;
use IO::Async::Loop;

BEGIN {
   # Install a fake resolver
   *IO::Async::Resolver::DNS::res_search = 
   *IO::Async::Resolver::DNS::res_query = sub {
      my ( $dname, $class, $type ) = @_;
      my $packet = Net::DNS::Packet->new( $dname, $type, $class );
      $packet->push( answer => Net::DNS::RR->new( "$dname. 86400 A 10.0.0.1" ) );
      return $packet->data;
   };
}

use IO::Async::Resolver::DNS;

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

my $resolver = $loop->resolver;

{
   can_ok( $resolver, "res_query" );

   my $f = $resolver->res_query(
      dname => "www.cpan.org",
      type  => "A",
   );

   wait_for { $f->is_ready };
   my $result = $f->get;

   isa_ok( $result, "Net::DNS::Packet", '$result from ->res_query isa Net::DNS::Packet' );

   my @answers = $result->answer;
   is( scalar @answers, 1, '$result from ->res_query contains an answer' );
   is( $answers[0]->type, "A", '$answer[0] is A record' );
   is( $answers[0]->address, "10.0.0.1", '$answer[0] address is 10.0.0.1' );
}

{
   can_ok( $resolver, "res_search" );

   my $f = $resolver->res_search(
      dname => "www.cpan.org",
      type  => "A",
   );

   wait_for { $f->is_ready };
   my $result = $f->get;

   isa_ok( $result, "Net::DNS::Packet", '$result from ->res_search isa Net::DNS::Packet' );

   my @answers = $result->answer;
   is( scalar @answers, 1, '$result from ->res_query contains an answer' );
   is( $answers[0]->type, "A", '$answer[0] is A record' );
   is( $answers[0]->address, "10.0.0.1", '$answer[0] address is 10.0.0.1' );
}

done_testing;
