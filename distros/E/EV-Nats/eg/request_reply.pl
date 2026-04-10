#!/usr/bin/env perl
# Request/reply service pattern
use strict;
use warnings;
use EV;
use EV::Nats;

my $mode = shift // 'both'; # 'service', 'client', or 'both'

my $nats;
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "error: @_\n" },
    on_connect => sub {
        print "connected\n";

        if ($mode eq 'service' || $mode eq 'both') {
            # echo service: uppercases the payload
            $nats->subscribe('svc.upper', sub {
                my ($subject, $payload, $reply) = @_;
                $nats->publish($reply, uc $payload) if $reply;
            });

            # time service
            $nats->subscribe('svc.time', sub {
                my ($subject, $payload, $reply) = @_;
                $nats->publish($reply, scalar localtime) if $reply;
            });
            print "services registered\n";
        }

        if ($mode eq 'client' || $mode eq 'both') {
            my $done = 0;
            my $check_done = sub {
                if (++$done >= 2) {
                    $nats->disconnect;
                    EV::break;
                }
            };

            # small delay for sub propagation in 'both' mode
            my $t; $t = EV::timer 0.1, 0, sub {
                undef $t;
                $nats->request('svc.upper', 'hello world', sub {
                    my ($resp, $err) = @_;
                    print $err ? "upper error: $err\n" : "upper: $resp\n";
                    $check_done->();
                });
                $nats->request('svc.time', '', sub {
                    my ($resp, $err) = @_;
                    print $err ? "time error: $err\n" : "time: $resp\n";
                    $check_done->();
                });
            };
        }
    },
);

EV::run;
