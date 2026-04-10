#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

# demonstrates low-level auto-reconnect
$| = 1;

my $host = $ENV{KAFKA_HOST} // '127.0.0.1';
my $port = $ENV{KAFKA_PORT} // 9092;

my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
$conn->auto_reconnect(1, 2000); # reconnect after 2 seconds

$conn->on_error(sub {
    print "error: @_\n";
});

$conn->on_connect(sub {
    print "connected! state=" . $conn->state . "\n";
    my $vers = $conn->api_versions;
    print "  APIs: " . scalar(keys %$vers) . " supported\n";
});

$conn->on_disconnect(sub {
    print "disconnected, will reconnect in 2s...\n";
});

print "connecting to $host:$port (try stopping/starting the broker)...\n";
$conn->connect($host, $port, 5.0);

$SIG{INT} = sub {
    print "\nshutting down\n";
    $conn->auto_reconnect(0);
    $conn->disconnect;
    EV::break;
};

EV::run;
