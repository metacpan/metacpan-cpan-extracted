#!/usr/bin/env perl
# Log aggregator — fan-in: many sources publish, one collector subscribes
# Usage:
#   perl eg/log_aggregator.pl collect          — run collector
#   perl eg/log_aggregator.pl emit <source>    — emit logs from a source
use strict;
use warnings;
use EV;
use EV::Nats;

my $mode   = shift || 'collect';
my $source = shift || "src$$";

my $nats;
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "nats: @_\n" },
    on_connect => sub {
        if ($mode eq 'collect') {
            print "collecting logs from all sources...\n";

            # Subscribe to all log subjects
            $nats->subscribe('logs.>', sub {
                my ($subject, $payload) = @_;
                my ($prefix, $src, $level) = split /\./, $subject, 3;
                printf "[%s] %-5s %s: %s\n", scalar localtime, uc($level // 'info'), $src, $payload;
            });

            # Stats every 10s
            my $t; $t = EV::timer 10, 10, sub {
                my %s = $nats->stats;
                printf "--- %d msgs received, %d bytes ---\n", $s{msgs_in}, $s{bytes_in};
            };
        } else {
            print "emitting logs as '$source'...\n";
            my @levels = qw(info warn error debug);
            my @messages = (
                "request processed in 12ms",
                "connection pool exhausted",
                "disk usage at 85%",
                "cache miss for key users:42",
                "retry attempt 3/5",
                "response sent to client",
            );
            my $n = 0;
            my $t; $t = EV::timer 0.5, 0.5, sub {
                my $level = $levels[rand @levels];
                my $msg   = $messages[rand @messages];
                $nats->publish("logs.$source.$level", $msg);
                if (++$n >= 20) {
                    undef $t;
                    $nats->drain(sub { EV::break });
                }
            };
        }
    },
);

EV::run;
