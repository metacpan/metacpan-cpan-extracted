use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

my $broker = $ENV{TEST_KAFKA_BROKER} || '127.0.0.1:9092';
plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};
plan tests => 5;

my $topic = 'ev-kafka-group-test';
my @received;

my $kafka = EV::Kafka->new(
    brokers    => $broker,
    acks       => 1,
    on_error   => sub { diag "error: @_" },
    on_message => sub {
        my ($t, $p, $o, $k, $v, $h) = @_;
        push @received, { topic => $t, partition => $p, offset => $o, key => $k, value => $v };
        diag "received: offset=$o key=$k value=$v";
    },
);

$kafka->connect(sub {
    my $meta = shift;
    ok $meta, 'connected and got metadata';

    # produce some messages first
    my $produced = 0;
    for my $i (1..3) {
        $kafka->produce($topic, "gkey$i", "gval$i", sub {
            my ($res, $err) = @_;
            $produced++;
            if ($produced == 3) {
                diag "produced 3 messages, waiting for topic to settle...";
                my $t; $t = EV::timer 5, 0, sub {
                    undef $t;
                    diag "subscribing...";
                    _do_subscribe();
                };
            }
        });
    }
});

sub _do_subscribe {
    $kafka->subscribe($topic,
        group_id           => 'ev-kafka-test-group',
        session_timeout    => 10000,
        rebalance_timeout  => 15000,
        heartbeat_interval => 1,
        on_assign          => sub {
            my $parts = shift;
            ok ref $parts eq 'ARRAY', 'on_assign called with partitions';
            diag "assigned: " . scalar @$parts . " partitions";
            for my $p (@$parts) {
                diag "  $p->{topic}:$p->{partition} from offset $p->{offset}";
            }

            # wait a bit for messages to be fetched
            my $t; $t = EV::timer 3, 0, sub {
                undef $t;
                ok scalar @received > 0, 'received messages via consumer group';
                diag "received " . scalar @received . " messages";

                # commit offsets then unsubscribe
                $kafka->commit(sub {
                    my ($res_or_err) = @_;
                    diag "commit result: " . (ref $res_or_err ? "hash" : ($res_or_err // "undef"));
                    pass 'commit completed';

                    # unsubscribe after commit completes
                    $kafka->unsubscribe;
                    pass 'unsubscribed';

                    EV::break;
                });
            };
        },
        on_revoke => sub {
            diag "revoked";
        },
    );
}

my $timeout = EV::timer 30, 0, sub {
    diag "timeout";
    diag "received so far: " . scalar @received;
    EV::break;
};

EV::run;
