use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

my $broker = $ENV{TEST_KAFKA_BROKER} || '127.0.0.1:9092';
my ($host, $port) = split /:/, $broker;

plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};
plan tests => 8;

my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);

$conn->on_error(sub { diag "error: @_"; EV::break });
$conn->on_connect(sub {
    ok $conn->connected, 'connected';

    # first produce a message so we have something to fetch
    $conn->produce('ev-kafka-test', 0, 'fetchkey', 'fetchval', sub {
        my ($res, $err) = @_;
        ok !$err, 'produce ok';
        diag "produced at offset " . $res->{topics}[0]{partitions}[0]{base_offset};

        # list offsets to find earliest
        $conn->list_offsets('ev-kafka-test', 0, -2, sub {
            my ($lres, $lerr) = @_;
            ok !$lerr, 'list_offsets ok';
            my $earliest = $lres->{topics}[0]{partitions}[0]{offset};
            diag "earliest offset: $earliest";
            ok defined $earliest, 'got earliest offset';

            # now fetch from earliest
            $conn->fetch('ev-kafka-test', 0, $earliest, sub {
                my ($fres, $ferr) = @_;
                ok !$ferr, 'fetch ok';

                my $parts = $fres->{topics}[0]{partitions};
                ok $parts && @$parts, 'got partition data';

                my $records = $parts->[0]{records};
                ok ref $records eq 'ARRAY', 'got records array';
                ok scalar @$records > 0, 'got records';

                if (@$records) {
                    for my $r (@$records) {
                        diag sprintf "  offset=%d key=%s value=%s",
                            $r->{offset}, $r->{key} // 'null', $r->{value} // 'null';
                    }
                }

                EV::break;
            });
        });
    });
});

$conn->connect($host, $port + 0, 5.0);
my $timeout = EV::timer 10, 0, sub { diag "timeout"; EV::break };
EV::run;
