use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

my $broker = $ENV{TEST_KAFKA_BROKER} || '127.0.0.1:9092';
my ($host, $port) = split /:/, $broker;

plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};
plan tests => 5;

my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);

my $connected = 0;
my $api_ver;
my $meta;

$conn->on_error(sub { diag "error: @_"; EV::break });
$conn->on_connect(sub {
    $connected = 1;
    ok $conn->connected, 'connected';

    $api_ver = $conn->api_versions;
    ok ref $api_ver eq 'HASH', 'api_versions returns hash';
    ok exists $api_ver->{0}, 'Produce API supported';

    diag "supported APIs: " . join(', ', sort { $a <=> $b } keys %$api_ver);

    # request metadata for all topics
    $conn->metadata(undef, sub {
        my ($result, $err) = @_;
        ok !$err, 'metadata: no error';
        $meta = $result;
        ok ref $meta->{brokers} eq 'ARRAY', 'metadata has brokers';
        diag "brokers: " . scalar @{$meta->{brokers}};
        diag "topics: " . scalar @{$meta->{topics}};
        EV::break;
    });
});

$conn->connect($host, $port + 0, 5.0);

my $timeout = EV::timer 10, 0, sub {
    diag "timeout";
    EV::break;
};

EV::run;

unless ($connected) {
    fail 'did not connect' for 1..5;
}
