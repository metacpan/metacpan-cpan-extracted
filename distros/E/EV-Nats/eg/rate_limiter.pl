#!/usr/bin/env perl
# Rate limiter service — request/reply pattern for centralized rate limiting
# Usage:
#   perl eg/rate_limiter.pl service     — run the limiter service
#   perl eg/rate_limiter.pl client      — run a client that checks limits
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
            # Rate limit state: key -> { count, window_start }
            my %limits;
            my $max_per_window = 5;
            my $window_secs    = 10;

            $nats->subscribe('ratelimit.check', sub {
                my ($subj, $payload, $reply) = @_;
                return unless $reply;

                my $key = $payload;
                my $now = time;

                $limits{$key} //= { count => 0, start => $now };
                my $l = $limits{$key};

                # Reset window if expired
                if ($now - $l->{start} >= $window_secs) {
                    $l->{count} = 0;
                    $l->{start} = $now;
                }

                $l->{count}++;
                my $allowed = $l->{count} <= $max_per_window;
                my $remaining = $max_per_window - $l->{count};
                $remaining = 0 if $remaining < 0;

                $nats->publish($reply, $allowed ? "OK:$remaining" : "DENIED:0");
            });
            print "rate limiter service running ($max_per_window req/$window_secs" . "s)\n";
        }

        if ($mode eq 'client' || $mode eq 'both') {
            my $t; $t = EV::timer 0.2, 0, sub {
                undef $t;
                my $done = 0;
                for my $i (1..8) {
                    $nats->request('ratelimit.check', "user:alice", sub {
                        my ($resp, $err) = @_;
                        if ($err) {
                            print "req $i: error: $err\n";
                        } else {
                            my ($status, $remaining) = split /:/, $resp;
                            printf "req %d: %s (remaining: %s)\n", $i, $status, $remaining;
                        }
                        if (++$done >= 8) {
                            $nats->disconnect;
                            EV::break;
                        }
                    }, 2000);
                }
            };
        }
    },
);

EV::run;
