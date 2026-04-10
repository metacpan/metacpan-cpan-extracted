use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

my $broker = $ENV{TEST_KAFKA_BROKER} || '127.0.0.1:9092';
my ($host, $port) = split /:/, $broker;

plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};
plan tests => 4;

my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);

$conn->on_error(sub { diag "error: @_"; EV::break });
$conn->on_connect(sub {
    ok $conn->connected, 'connected';

    # request metadata first to auto-create topic, then produce
    $conn->metadata(['ev-kafka-test'], sub {
        my ($meta, $merr) = @_;
        diag "metadata fetched, producing...";

        # small delay to let topic creation settle
        my $t; $t = EV::timer 0.5, 0, sub {
            undef $t;
            $conn->produce('ev-kafka-test', 0, 'key1', 'hello world', sub {
        my ($result, $err) = @_;
        ok !$err, 'produce: no error';
        ok ref $result eq 'HASH', 'produce: got result hash';

        my $topics = $result->{topics};
        if ($topics && @$topics) {
            my $parts = $topics->[0]{partitions};
            if ($parts && @$parts) {
                my $p = $parts->[0];
                is $p->{error_code}, 0, "produce: partition error_code=0";
                diag "base_offset=" . $p->{base_offset};
            }
        }
            EV::break;
            });
        };
    });
});

$conn->connect($host, $port + 0, 5.0);

my $timeout = EV::timer 10, 0, sub {
    diag "timeout";
    EV::break;
};

EV::run;
