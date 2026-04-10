use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

my $broker = $ENV{TEST_KAFKA_BROKER} || '127.0.0.1:9092';
plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};
plan tests => 6;

my ($host, $port) = split /:/, $broker;
my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
$conn->on_error(sub { diag "error: @_"; EV::break });

$conn->on_connect(sub {
    ok $conn->connected, 'connected';

    # ensure topic
    $conn->metadata(['compress-test'], sub {
        my $t; $t = EV::timer 1, 0, sub {
            undef $t;

            # produce with gzip
            $conn->produce('compress-test', 0, 'gzip-key', 'gzip-value' x 10,
                { compression => 'gzip' }, sub {
                my ($res, $err) = @_;
                ok !$err, 'gzip produce ok';
                my $offset = $res->{topics}[0]{partitions}[0]{base_offset};
                diag "gzip produced at offset $offset";

                # produce with lz4
                $conn->produce('compress-test', 0, 'lz4-key', 'lz4-value' x 10,
                    { compression => 'lz4' }, sub {
                    my ($res2, $err2) = @_;
                    ok !$err2, 'lz4 produce ok';

                    # produce uncompressed
                    $conn->produce('compress-test', 0, 'none-key', 'none-value', sub {
                        my ($res3, $err3) = @_;
                        ok !$err3, 'uncompressed produce ok';

                        # fetch all back
                        $conn->fetch('compress-test', 0, $offset, sub {
                            my ($fres, $ferr) = @_;
                            ok !$ferr, 'fetch ok';
                            my $recs = $fres->{topics}[0]{partitions}[0]{records};
                            ok scalar @$recs >= 3, "fetched " . scalar(@$recs) . " records";
                            for my $r (@$recs) {
                                diag "  key=$r->{key} value_len=" . length($r->{value} // '');
                            }
                            $conn->disconnect;
                            EV::break;
                        });
                    });
                });
            });
        };
    });
});

$conn->connect($host, $port + 0, 5.0);
my $timeout = EV::timer 15, 0, sub { diag "timeout"; EV::break };
EV::run;
