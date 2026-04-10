#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

$| = 1;

# demonstrates error handling at both connection and cluster levels

# --- low-level: connection refused ---
{
    print "1. Connection refused (low-level)\n";
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    $conn->on_error(sub {
        print "  on_error: @_\n";
        EV::break;
    });
    $conn->connect('127.0.0.1', 19999, 2.0); # nothing listening
    EV::run;
    print "\n";
}

# --- low-level: connect timeout ---
{
    print "2. Connect timeout (low-level)\n";
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    $conn->on_error(sub {
        print "  on_error: @_\n";
        EV::break;
    });
    $conn->connect('192.0.2.1', 9092, 1.0); # RFC 5737 TEST-NET, will timeout
    EV::run;
    print "\n";
}

# --- cluster: broker unreachable ---
{
    print "3. All brokers unreachable (cluster)\n";
    my $kafka = EV::Kafka->new(
        brokers  => '127.0.0.1:19998,127.0.0.1:19999',
        on_error => sub {
            print "  on_error: @_\n";
            EV::break;
        },
    );
    $kafka->connect;
    my $t = EV::timer 5, 0, sub { print "  (gave up)\n"; EV::break };
    EV::run;
    print "\n";
}

# --- low-level: produce to non-existent topic (no auto-create) ---
{
    print "4. Produce error code handling\n";
    print "  (requires running broker at KAFKA_BROKER)\n";
    my $host = $ENV{KAFKA_HOST} // '127.0.0.1';
    my $port = $ENV{KAFKA_PORT} // 9092;
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    $conn->on_error(sub { print "  on_error: @_\n"; EV::break });
    $conn->on_connect(sub {
        # produce to partition 999 which doesn't exist
        $conn->produce('test-topic', 999, 'k', 'v', sub {
            my ($res, $err) = @_;
            if ($err) {
                print "  callback error: $err\n";
            } else {
                my $ec = $res->{topics}[0]{partitions}[0]{error_code};
                print "  error_code=$ec (expected non-zero for bad partition)\n";
            }
            $conn->disconnect;
        });
    });
    $conn->connect($host, $port, 3.0);
    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run;
}
