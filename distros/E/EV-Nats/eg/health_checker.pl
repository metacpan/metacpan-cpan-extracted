#!/usr/bin/env perl
# Health checker — periodically pings services, reports status
# Run services: perl eg/health_checker.pl service <name>
# Run checker:  perl eg/health_checker.pl monitor
use strict;
use warnings;
use EV;
use EV::Nats;

my $mode = shift || 'both';
my $name = shift || "svc$$";

my $nats;
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "nats: @_\n" },
    on_connect => sub {
        if ($mode eq 'service' || $mode eq 'both') {
            # Register health endpoint
            $nats->subscribe("health.$name", sub {
                my ($subj, $payload, $reply) = @_;
                return unless $reply;
                # Simulate health: 90% healthy, 10% degraded
                my $status = rand() < 0.9 ? 'healthy' : 'degraded';
                $nats->publish($reply, "$name:$status:$$:" . int(rand(100)) . "ms");
            });
            print "service '$name' registered health endpoint\n";

            if ($mode eq 'both') {
                # Also register a second service for demo
                $nats->subscribe("health.db", sub {
                    my ($subj, $payload, $reply) = @_;
                    return unless $reply;
                    $nats->publish($reply, "db:healthy:$$:2ms");
                });
                $nats->subscribe("health.cache", sub {
                    my ($subj, $payload, $reply) = @_;
                    return unless $reply;
                    $nats->publish($reply, "cache:healthy:$$:0ms");
                });
            }
        }

        if ($mode eq 'monitor' || $mode eq 'both') {
            my @services = $mode eq 'both'
                ? ($name, 'db', 'cache')
                : split(/,/, $ENV{SERVICES} || $name);

            my $checks = 0;
            my $t; $t = EV::timer 1, 2, sub {
                $checks++;
                print "\n--- health check #$checks ---\n";
                for my $svc (@services) {
                    $nats->request("health.$svc", 'ping', sub {
                        my ($resp, $err) = @_;
                        if ($err) {
                            printf "  %-10s DOWN (%s)\n", $svc, $err;
                        } else {
                            my ($n, $status, $pid, $latency) = split /:/, $resp;
                            printf "  %-10s %-8s pid=%s latency=%s\n", $n, $status, $pid, $latency;
                        }
                    }, 1000);
                }
                if ($checks >= 3) {
                    undef $t;
                    my $done; $done = EV::timer 2, 0, sub {
                        undef $done;
                        $nats->disconnect;
                        EV::break;
                    };
                }
            };
        }
    },
);

EV::run;
