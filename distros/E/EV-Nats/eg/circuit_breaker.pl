#!/usr/bin/env perl
# Circuit breaker — track failure rate, trip breaker, auto-recover
# Usage:
#   perl eg/circuit_breaker.pl service   — flaky service (fails 40%)
#   perl eg/circuit_breaker.pl client    — client with circuit breaker
#   perl eg/circuit_breaker.pl both      — run both in one process
use strict;
use warnings;
use EV;
use EV::Nats;

my $mode = shift || 'both';

my $nats;
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "nats: @_\n" },
    on_connect => sub {
        if ($mode eq 'service' || $mode eq 'both') {
            $nats->subscribe('backend.api', sub {
                my ($subj, $payload, $reply) = @_;
                return unless $reply;
                # 40% failure rate
                if (rand() < 0.4) {
                    $nats->publish($reply, 'ERROR:service overloaded');
                } else {
                    $nats->publish($reply, "OK:processed $payload");
                }
            });
            print "flaky service running (40% failure rate)\n";
        }

        if ($mode eq 'client' || $mode eq 'both') {
            # Circuit breaker state
            my $state = 'closed';  # closed=normal, open=reject, half_open=probe
            my $failures = 0;
            my $threshold = 3;     # trip after N consecutive failures
            my $cooldown = 5;      # seconds before half-open probe
            my $recovery_timer;

            my $trip = sub {
                $state = 'open';
                $failures = 0;
                print "  CIRCUIT OPEN — rejecting requests for ${cooldown}s\n";
                $recovery_timer = EV::timer $cooldown, 0, sub {
                    $state = 'half_open';
                    print "  CIRCUIT HALF-OPEN — sending probe\n";
                    undef $recovery_timer;
                };
            };

            my $call_service = sub {
                my ($id, $done_cb) = @_;

                if ($state eq 'open') {
                    print "req $id: REJECTED (circuit open)\n";
                    $done_cb->();
                    return;
                }

                $nats->request('backend.api', "job-$id", sub {
                    my ($resp, $err) = @_;
                    if ($err || ($resp && $resp =~ /^ERROR/)) {
                        $failures++;
                        printf "req %d: FAIL (%s) failures=%d/%d\n",
                            $id, $err || $resp, $failures, $threshold;
                        if ($failures >= $threshold && $state ne 'open') {
                            $trip->();
                        }
                    } else {
                        if ($state eq 'half_open') {
                            $state = 'closed';
                            print "  CIRCUIT CLOSED — service recovered\n";
                        }
                        $failures = 0;
                        print "req $id: OK ($resp)\n";
                    }
                    $done_cb->();
                }, 2000);
            };

            my $req = 0;
            my $t; $t = EV::timer 0.3, 0.3, sub {
                $req++;
                $call_service->($req, sub {
                    if ($req >= 20) {
                        undef $t;
                        undef $recovery_timer;
                        $nats->disconnect;
                        EV::break;
                    }
                });
            };
        }
    },
);

EV::run;
