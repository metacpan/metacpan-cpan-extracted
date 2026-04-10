use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

my $broker = $ENV{TEST_KAFKA_BROKER} || '127.0.0.1:9092';
plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};
plan tests => 7;

my $kafka = EV::Kafka->new(
    brokers  => $broker,
    acks     => 1,
    on_error => sub { diag "cluster error: @_" },
);

isa_ok $kafka, 'EV::Kafka::Client';

$kafka->connect(sub {
    my $meta = shift;
    ok $meta, 'got metadata';
    ok ref $meta->{brokers} eq 'ARRAY', 'metadata has brokers';

    # produce through cluster
    $kafka->produce('ev-kafka-cluster-test', 'mykey', 'myvalue', sub {
        my ($result, $err) = @_;
        ok !$err, 'cluster produce: no error';
        ok ref $result eq 'HASH', 'cluster produce: got result';

        my $offset = $result->{topics}[0]{partitions}[0]{base_offset};
        diag "produced at offset $offset";

        # fetch via poll
        $kafka->assign([{
            topic     => 'ev-kafka-cluster-test',
            partition => 0,
            offset    => $offset,
        }]);

        $kafka->poll(sub {
            pass 'poll completed';
            $kafka->close(sub {
                pass 'closed';
                EV::break;
            });
        });
    });
});

my $timeout = EV::timer 10, 0, sub { diag "timeout"; EV::break };
EV::run;
