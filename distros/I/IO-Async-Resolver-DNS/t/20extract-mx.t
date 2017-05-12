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
      $packet->push( answer => Net::DNS::RR->new( "example.com. 86400 MX 10 mail.example.com." ) );
      $packet->push( answer => Net::DNS::RR->new( "example.com. 86400 MX 20 mail.backuphost.net." ) );
      $packet->push( additional => Net::DNS::RR->new( "mail.example.com. 86400 A 10.0.0.1" ) );
      $packet->push( additional => Net::DNS::RR->new( "mail.example.com. 86400 A 10.0.0.2" ) );
      $packet->push( additional => Net::DNS::RR->new( "mail.example.com. 86400 AAAA fd00::1" ) );
      return $packet->data;
   };
}

use IO::Async::Resolver::DNS;

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

my $resolver = $loop->resolver;

my ( $pkt, @mx ) = $resolver->res_query(
   dname => "example.com",
   type  => "MX",
)->get;

isa_ok( $pkt, "Net::DNS::Packet", '$pkt from ->res_query isa Net::DNS::Packet' );

is_deeply( \@mx,
   [ { exchange   => "mail.example.com",
       preference => 10,
       address    => [ "10.0.0.1", "10.0.0.2", "fd00:0:0:0:0:0:0:1" ] },
     { exchange   => "mail.backuphost.net",
       preference => 20 } ],
   'Sorted and processed MX records' );

done_testing;
