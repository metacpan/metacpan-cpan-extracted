#!/usr/bin/perl
#
# Copyright (C) 2013 by Lieven Hollevoet

# This test runs the communication test.

use strict;

use Test::More;
use Test::Requires qw/Test::SharedFork/;
use Test::SharedFork;
use IO::Select;
use IO::Socket::INET;

BEGIN { use_ok('Device::Solenodrive'); }

my $tcp = IO::Socket::INET->new(
    Listen    => 5,
    Proto     => 'tcp',
    LocalAddr => '127.0.0.1',
    LocalPort => 0
) or plan skip_all => "Failed to open TCP server on loopback address: $!";
my $tcp_port = $tcp->sockport;

my $pid = fork();

# Make a TCP test server in a spearate thread and connect to it with the bootloader from the parent thread
if ( $pid == 0 ) {

    # child
    my $sel = IO::Select->new($tcp);
    $sel->can_read(10) or die;
    my $client = $tcp->accept;
    ok $client, 'client accepted';
    $sel = IO::Select->new($client);
    $sel->can_read(10) or die;
    my ( $buf, $bytes, $resp );

    # Handle enumeration request
    $bytes = sysread $client, $buf, 2048;
    is $bytes, 10, 'sync packet length';
    is $buf, "\x0F\xFE\xFE\xFE\xFEE0\xCF\xE0\x04", "Got enumeration request";

    # Send first enumeration response
    $resp = "\x0F\xAB\xCD\xEF\x01E3\x75\xA3\x04";
    syswrite $client, $resp, length($resp);

    # And second one
    sleep(1);
    $resp = "\x0F\xAB\xCD\xEF\x02E4\xC2\x8A\x04";
    syswrite $client, $resp, length($resp);

    # Handle command
    $sel->can_read(10) or die;
    $bytes = sysread $client, $buf, 2048;
    is $bytes, 10, 'set output request length';
    is $buf, "\x0f\xAB\xCD\xEF\x02D3\x14\xc9\x04",
        "Board 2 channel 3 drive command OK";
    $resp = "\x0F\xAB\xCD\xEF\x02S3\xF0\x53\x04";
    syswrite $client, $resp, length($resp);

}
elsif ($pid) {

    #parent
    my $soleno = Device::Solenodrive->new(
        device  => '127.0.0.1' . ":" . $tcp_port,
        verbose => 3
    );
    ok $soleno, 'object created';

    # Connect to controller
    $soleno->connect_target();
    $soleno->enumerate();

    # Send test command
    $soleno->set( "ABCDEF02", 3 );

    # Wait response
    my $response = $soleno->_read_packet(5);
    is $response, "ABCDEF025333", "Expected response on set command received";

    #is ($soleno->program, 1, 'Programming over TCP done');
    waitpid $pid, 0;
    done_testing();
}
else {
    die $!;
}
