#!/usr/bin/perl
use strict;
BEGIN {
	$| 
 = 1;
	$^W = 1;
}

use Test::More;
use IO::Socket::Multicast;

plan skip_all => 'Developer testing only'
    unless (defined $ENV{TEST_UNSAFE} && $ENV{TEST_UNSAFE} == 1);

plan tests => 4;

my $MCAST_ADDR = '225.0.0.1';
my $MCAST_PORT = 9999;

my $s = IO::Socket::Multicast->new(
    LocalPort => $MCAST_PORT,
    Blocking  => 0,
);

$s->mcast_loopback(1);

my $payload =  "IO::Socket::Multicast test packet - $$ $0";

ok( $s->mcast_add( $MCAST_ADDR ) , "Join $MCAST_ADDR" );
ok( 
    $s->mcast_send( $payload ,"$MCAST_ADDR:$MCAST_PORT") , 
    "Send to $MCAST_ADDR:$MCAST_PORT" 
);

my $data;
ok( $s->recv( $data, 1024 ) , 'Received test data' );
ok( $data eq $payload , 'Received data matches sent data' );

