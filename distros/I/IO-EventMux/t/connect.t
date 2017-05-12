use strict;
use warnings;

use Test::More tests => 10;
use IO::EventMux;
use IO::Socket::INET;
use IO::Select;
use Socket;

#plan skip_all => "Skip for now";

my $mux = IO::EventMux->new();

my $tcp_urllisten = $mux->listen("tcp://127.0.0.1:11046");
my $tcp_url = $mux->connect("tcp://127.0.0.1:11046");

is($mux->type($tcp_urllisten), 'stream', 
    "TCP listen stream created base on URL syntax");
is($mux->type($tcp_url), 'stream', 
    "TCP connect stream created base on URL syntax");

my $tcp_socketlisten = $mux->listen(
    LocalPort    => 11047,
    LocalAddr    => "127.0.0.1",
    ReuseAddr    => 1,    
    Proto        => 'tcp',
    Listen       => 5,
    Blocking     => 0,
);

my $tcp_socket = $mux->connect(
    PeerPort    => 11047,
    PeerAddr    => "127.0.0.1",
    Proto        => 'tcp',
    Blocking     => 0,
);

is($mux->type($tcp_socketlisten), 'stream', 
    "TCP listen stream created base on IO::Socket syntax");
is($mux->type($tcp_socket), 'stream', 
    "TCP connect stream created base on IO::Socket syntax");

my $udp_urllisten = $mux->listen("udp://127.0.0.1:11048");
my $udp_url = $mux->connect("udp://127.0.0.1:11048");

my $udp_socketlisten = $mux->listen(
    LocalPort    => 11049,
    LocalAddr    => "127.0.0.1",
    ReuseAddr    => 1,    
    Proto        => 'udp',
    Blocking     => 0,
);

my $udp_socket = $mux->connect(
    PeerAddr => "127.0.0.1",
    PeerPort => 11049,
    Proto    => 'udp',
    Blocking => 0,
);

$mux->send($udp_socket, "Hello");
$mux->send($udp_url, "Hello");

my $count = 8;
while(my $event = $mux->mux(5)) {
    #use Data::Dumper; print Dumper($event);
    pass("TCP URL ready") 
        if $event->{type} eq 'ready' and $event->{fh} eq $tcp_url;
    pass("TCP Socket ready") 
        if $event->{type} eq 'ready' and $event->{fh} eq $tcp_socket;
    pass("TCP Listen URL accepted") 
        if $event->{type} eq 'accepted' and $event->{parent_fh} eq $tcp_urllisten;
    pass("TCP Listen Socket accepted") 
        if $event->{type} eq 'accepted' and $event->{parent_fh} eq $tcp_socketlisten;
    pass("UDP Listen Socket read") 
        if $event->{type} eq 'read' and $event->{fh} eq $udp_socketlisten;
    pass("UDP Listen URL read") 
        if $event->{type} eq 'read' and $event->{fh} eq $udp_urllisten;

    die "Got timeout: $count" if $event->{type} eq 'timeout';
    exit if !--$count;
}

