#!/usr/bin/perl

use warnings;
use strict;

use FindBin qw($Bin);

use lib "$Bin/../lib";

use Net::Stomp;

my $stomp = Net::Stomp->new({'hostname' => 'localhost', 'port' => 61613});

$stomp->connect({'login' => 'hello', 'passcode' => 'there'});

$stomp->subscribe(
    {
        'destination'           => '/topic/log',
        'ack'                   => 'client',
        'activemq.prefetchSize' => 1
    }
);

while (1) {
    my $frame = $stomp->receive_frame();

    printf('%s', $frame->body());

    $stomp->ack({'frame' => $frame});
}

$stomp->disconnect();
