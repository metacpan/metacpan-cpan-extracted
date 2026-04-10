#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

# Low-level API: direct broker connection without cluster layer
$| = 1;

my $host = $ENV{KAFKA_HOST} // '127.0.0.1';
my $port = $ENV{KAFKA_PORT} // 9092;

my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
$conn->on_error(sub { die "error: @_\n" });

$conn->on_connect(sub {
    print "connected to $host:$port\n";

    my $vers = $conn->api_versions;
    print "supported APIs: " . join(', ', sort { $a <=> $b } keys %$vers) . "\n";

    # fetch cluster metadata
    $conn->metadata(undef, sub {
        my ($meta, $err) = @_;
        die "metadata: $err" if $err;

        print "\nbrokers:\n";
        for my $b (@{$meta->{brokers}}) {
            printf "  node %d: %s:%d\n", $b->{node_id}, $b->{host}, $b->{port};
        }

        print "\ntopics:\n";
        for my $t (@{$meta->{topics}}) {
            printf "  %s (%d partitions)\n", $t->{name},
                scalar @{$t->{partitions}};
            for my $p (@{$t->{partitions}}) {
                printf "    partition %d  leader=%d\n",
                    $p->{partition}, $p->{leader};
            }
        }

        # produce directly to partition 0
        $conn->produce('test-topic', 0, 'direct-key', 'direct-value', sub {
            my ($res, $err) = @_;
            die "produce: $err" if $err;
            my $offset = $res->{topics}[0]{partitions}[0]{base_offset};
            print "\nproduced at offset $offset\n";

            # fetch it back
            $conn->fetch('test-topic', 0, $offset, sub {
                my ($fres, $ferr) = @_;
                die "fetch: $ferr" if $ferr;

                my $records = $fres->{topics}[0]{partitions}[0]{records};
                print "\nfetched " . scalar(@$records) . " record(s):\n";
                for my $r (@$records) {
                    printf "  offset=%d key=%s value=%s\n",
                        $r->{offset}, $r->{key} // 'null', $r->{value} // 'null';
                }
                $conn->disconnect;
                EV::break;
            });
        });
    });
});

$conn->connect($host, $port, 5.0);

my $t = EV::timer 15, 0, sub { die "timeout\n" };
EV::run;
