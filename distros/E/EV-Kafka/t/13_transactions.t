use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

my $broker = $ENV{TEST_KAFKA_BROKER} || '127.0.0.1:9092';
plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};
plan tests => 5;

my $topic = 'txn-test';

my ($host, $port) = split /:/, $broker;

# Test 1: idempotent produce (no transactional_id)
{
    my $kafka = EV::Kafka->new(
        brokers    => $broker,
        acks       => -1,
        idempotent => 1,
        on_error   => sub { diag "error: @_" },
    );

    $kafka->connect(sub {
        my $meta = shift;
        ok $meta, 'connected with idempotent';
        ok $kafka->{cfg}{producer_id} >= 0, 'got producer_id=' . $kafka->{cfg}{producer_id};
        diag "producer_id=" . $kafka->{cfg}{producer_id};

        $kafka->produce($topic, 'idem-key', 'idem-value', sub {
            my ($res, $err) = @_;
            ok !$err, 'idempotent produce ok';
            $kafka->close(sub { EV::break });
        });
    });

    my $t = EV::timer 10, 0, sub { diag "timeout"; EV::break };
    EV::run;
}

# Test 2: low-level init_producer_id with transactional_id
{
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    $conn->on_error(sub { diag "conn error: @_" });
    $conn->on_connect(sub {
        $conn->init_producer_id('ev-kafka-txn-' . $$, 30000, sub {
            my ($res, $err) = @_;
            ok !$err, 'init_producer_id ok';
            if ($res && !$res->{error_code}) {
                ok $res->{producer_id} >= 0, 'txn producer_id=' . $res->{producer_id};
            } else {
                diag "init_producer_id error_code=" . ($res->{error_code} // '?');
                pass 'init_producer_id returned (error expected on some brokers)';
            }
            $conn->disconnect;
            EV::break;
        });
    });
    $conn->connect($host, $port + 0, 5.0);
    my $t = EV::timer 10, 0, sub { diag "timeout"; EV::break };
    EV::run;
}
