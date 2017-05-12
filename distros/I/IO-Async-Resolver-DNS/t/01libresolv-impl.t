#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Net::DNS::Packet;

eval { require Net::LibResolv and Net::LibResolv->VERSION(0.03) } or
   plan skip_all => "Missing Net::LibResolv";

require IO::Async::Resolver::DNS::LibResolvImpl;

my $data = IO::Async::Resolver::DNS::res_query( "www.cpan.org", "IN", "A" );
ok( defined $data, 'res_query' );

my $pkt = Net::DNS::Packet->new( \$data );
ok( defined $pkt, 'res_query returns valid DNS packet' );

# Since we don't want to be too sensitive to what DNS actually claims about
# www.cpan.org at the current time, just check the question is what we asked
is( ($pkt->question)[0]->qname,  "www.cpan.org", '$pkt qname' );
is( ($pkt->question)[0]->qclass, "IN",           '$pkt qclass' );
is( ($pkt->question)[0]->qtype,  "A",            '$pkt qtype' );

ok( defined IO::Async::Resolver::DNS::res_search( "www.cpan.org", "IN", "A" ),
    'res_search' );

done_testing;
