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
      $packet->push( answer => Net::DNS::RR->new( "_gopher._tcp.example.com. 86400 SRV 10 0 70 gopher.l.example.com." ) );
      $packet->push( answer => Net::DNS::RR->new( "_gopher._tcp.example.com. 86400 SRV 20 10 70 gopher1.example.com." ) );
      $packet->push( answer => Net::DNS::RR->new( "_gopher._tcp.example.com. 86400 SRV 20 10 70 gopher2.example.com." ) );
      $packet->push( answer => Net::DNS::RR->new( "_gopher._tcp.example.com. 86400 SRV 20 10 70 gopher3.example.com." ) );
      $packet->push( answer => Net::DNS::RR->new( "_gopher._tcp.example.com. 86400 SRV 30 0 70 gopher.backuphost.com." ) );
      $packet->push( additional => Net::DNS::RR->new( "gopher.l.example.com. 86400 A 10.0.0.1" ) );
      $packet->push( additional => Net::DNS::RR->new( "gopher1.example.com. 86400 A 10.0.1.1" ) );
      $packet->push( additional => Net::DNS::RR->new( "gopher2.example.com. 86400 A 10.0.1.2" ) );
      $packet->push( additional => Net::DNS::RR->new( "gopher3.example.com. 86400 A 10.0.1.3" ) );
      return $packet->data;
   };
}

use IO::Async::Resolver::DNS;

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

my $resolver = $loop->resolver;

my ( $pkt, @srv ) = $resolver->res_query(
   dname => "_gopher._tcp.example.com",
   type  => "SRV",
)->get;

isa_ok( $pkt, "Net::DNS::Packet", '$pkt from ->res_query isa Net::DNS::Packet' );

is( scalar @srv, 5, '->res_query yielded 5 records' );

is_deeply( $srv[0],
   { priority  => 10,
     weight    => 0,
     target    => "gopher.l.example.com",
     port      => 70,
     address   => [ "10.0.0.1" ] },
   'First returned SRV record' );

# Can't rely on the exact order of the middle three, but we'll sort them to be
# sure
is_deeply( [ sort { $a->{target} cmp $b->{target} } @srv[1..3] ],
   [ { priority  => 20,
       weight    => 10,
       target    => "gopher1.example.com",
       port      => 70,
       address   => [ "10.0.1.1" ] },
     { priority  => 20,
       weight    => 10,
       target    => "gopher2.example.com",
       port      => 70,
       address   => [ "10.0.1.2" ] },
     { priority  => 20,
       weight    => 10,
       target    => "gopher3.example.com",
       port      => 70,
       address   => [ "10.0.1.3" ] } ],
   'Middle three returned SRV records' );

is_deeply( $srv[4],
   { priority  => 30,
     weight    => 0,
     target    => "gopher.backuphost.com",
     port      => 70 },
   'Last returned SRV record' );

done_testing;
