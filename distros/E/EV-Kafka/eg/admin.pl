#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

# topic administration: create, list, delete
$| = 1;

my $host = $ENV{KAFKA_HOST} // '127.0.0.1';
my $port = $ENV{KAFKA_PORT} // 9092;

my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
$conn->on_error(sub { warn "error: @_\n" });

$conn->on_connect(sub {
    print "connected\n\n";

    # create a topic with 3 partitions
    print "creating topic 'admin-test' with 3 partitions...\n";
    $conn->create_topics(
        [{ name => 'admin-test', num_partitions => 3, replication_factor => 1 }],
        5000,
        sub {
            my ($res, $err) = @_;
            if ($err) { print "create error: $err\n" }
            else {
                for my $t (@{$res->{topics} // []}) {
                    printf "  %s: error_code=%d\n", $t->{name}, $t->{error_code};
                }
            }

            # list all topics via metadata
            print "\nlisting topics...\n";
            $conn->metadata(undef, sub {
                my ($meta, $merr) = @_;
                for my $t (@{$meta->{topics} // []}) {
                    printf "  %s (%d partitions)\n", $t->{name},
                        scalar @{$t->{partitions}};
                }

                # delete the topic
                print "\ndeleting 'admin-test'...\n";
                $conn->delete_topics(['admin-test'], 5000, sub {
                    my ($dres, $derr) = @_;
                    if ($derr) { print "delete error: $derr\n" }
                    else {
                        for my $t (@{$dres->{topics} // []}) {
                            printf "  %s: error_code=%d\n", $t->{name}, $t->{error_code};
                        }
                    }
                    $conn->disconnect;
                    EV::break;
                });
            });
        }
    );
});

$conn->connect($host, $port, 5.0);
my $t = EV::timer 15, 0, sub { die "timeout\n" };
EV::run;
