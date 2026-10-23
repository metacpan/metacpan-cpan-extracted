use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

my $broker = $ENV{TEST_KAFKA_BROKER} || '127.0.0.1:9092';
plan skip_all => 'set TEST_KAFKA_BROKER to run' unless $ENV{TEST_KAFKA_BROKER};

# Gate per codec: produce() croaks for a codec that was not built in,
# which would abort the whole async chain below. Probe the built
# artifact: a real encode sets the compression bits (attrs low byte at
# offset 22), encode without the codec falls back to uncompressed.
my %code = (gzip => 1, snappy => 2, lz4 => 3, zstd => 4);
my @codecs = grep {
    my $b = eval {
        EV::Kafka::_test_encode_batch([{ key => 'k', value => 'x' x 64 }],
            { compression => $code{$_} });
    };
    defined($b) && (ord(substr($b, 22, 1)) & 0x07) == $code{$_};
} qw(gzip lz4 zstd snappy);

plan tests => 4 + @codecs;

my ($host, $port) = split /:/, $broker;
my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
$conn->on_error(sub { diag "error: @_"; EV::break });

$conn->on_connect(sub {
    ok $conn->connected, 'connected';

    # ensure topic
    $conn->metadata(['compress-test'], sub {
        my $t; $t = EV::timer 1, 0, sub {
            undef $t;

            my $offset;
            my @steps = (
                (map {
                    my $codec = $_;
                    sub {
                        my ($next) = @_;
                        $conn->produce('compress-test', 0, "$codec-key", "$codec-value" x 10,
                            { compression => $codec }, sub {
                            my ($res, $err) = @_;
                            ok !$err, "$codec produce ok";
                            if (!$err) {
                                $offset //= $res->{topics}[0]{partitions}[0]{base_offset};
                                diag "$codec produced at offset $offset";
                            }
                            $next->();
                        });
                    };
                } @codecs),
                sub {
                    my ($next) = @_;
                    $conn->produce('compress-test', 0, 'none-key', 'none-value', sub {
                        my ($res, $err) = @_;
                        ok !$err, 'uncompressed produce ok';
                        $offset //= $res->{topics}[0]{partitions}[0]{base_offset}
                            if !$err;
                        $next->();
                    });
                },
                sub {
                    $conn->fetch('compress-test', 0, $offset // 0, sub {
                        my ($fres, $ferr) = @_;
                        ok !$ferr, 'fetch ok';
                        my $recs = $fres->{topics}[0]{partitions}[0]{records};
                        ok scalar @$recs >= 1 + @codecs, "fetched " . scalar(@$recs) . " records";
                        for my $r (@$recs) {
                            diag "  key=$r->{key} value_len=" . length($r->{value} // '');
                        }
                        $conn->disconnect;
                        EV::break;
                    });
                },
            );
            my $run; $run = sub {
                my $step = shift @steps;
                $step->($run);
            };
            $run->();
        };
    });
});

$conn->connect($host, $port + 0, 5.0);
my $timeout = EV::timer 15, 0, sub { diag "timeout"; EV::break };
EV::run;
