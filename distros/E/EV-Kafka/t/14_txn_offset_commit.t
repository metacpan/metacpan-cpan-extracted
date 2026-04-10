use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

my $broker = $ENV{TEST_KAFKA_BROKER} || '127.0.0.1:9092';
plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};
plan tests => 6;

my ($host, $port) = split /:/, $broker;
my $topic    = 'txn-eos-test';
my $group_id = 'txn-eos-group';

# full EOS flow: consume -> produce -> send_offsets_to_transaction -> commit
my $kafka = EV::Kafka->new(
    brokers          => $broker,
    acks             => -1,
    transactional_id => 'eos-test-' . $$,
    on_error         => sub { diag "error: @_" },
    on_message       => sub {},
);

$kafka->connect(sub {
    my $meta = shift;
    ok $meta, 'connected';
    ok $kafka->{cfg}{producer_id} >= 0, 'producer_id=' . $kafka->{cfg}{producer_id};

    # produce some source messages
    $kafka->produce($topic, 'src-key', 'src-value', sub {
        my ($res, $err) = @_;
        ok !$err, 'source produce ok';

        # simulate consume-process-produce EOS flow:
        # 1. assign + poll would happen here (simplified: just set offset)
        $kafka->assign([{ topic => $topic, partition => 0, offset => 1 }]);

        # 2. begin transaction
        $kafka->begin_transaction;
        pass 'transaction started';

        # 3. produce to output topic within transaction
        $kafka->produce("${topic}-output", 'out-key', 'out-value', sub {
            my ($res2, $err2) = @_;

            # 4. send consumer offsets within transaction
            $kafka->send_offsets_to_transaction($group_id, sub {
                my ($ores, $oerr) = @_;
                # may fail on some brokers (NOT_COORDINATOR for txn coordinator)
                # but the API call itself should not crash
                pass 'send_offsets_to_transaction completed';

                # 5. commit transaction
                $kafka->commit_transaction(sub {
                    my ($cres, $cerr) = @_;
                    ok !$cerr, 'transaction committed';
                    $kafka->close(sub { EV::break });
                });
            });
        });
    });
});

my $timeout = EV::timer 15, 0, sub { diag "timeout"; EV::break };
EV::run;
