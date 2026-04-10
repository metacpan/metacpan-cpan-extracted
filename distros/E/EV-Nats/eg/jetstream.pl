#!/usr/bin/env perl
# JetStream stream + publish + consume example
# Requires NATS server with JetStream enabled: nats-server -js
use strict;
use warnings;
use EV;
use EV::Nats;
use EV::Nats::JetStream;

my $nats;
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "nats error: @_\n" },
    on_connect => sub {
        print "connected\n";

        my $js = EV::Nats::JetStream->new(nats => $nats);

        # Create a stream
        $js->stream_create({
            name     => 'DEMO',
            subjects => ['demo.>'],
            retention => 'limits',
            max_msgs  => 1000,
        }, sub {
            my ($info, $err) = @_;
            if ($err) {
                warn "stream create: $err (may already exist)\n";
            } else {
                print "stream created: $info->{config}{name}\n";
            }

            # Publish with ack
            my $sent = 0;
            my $send_next; $send_next = sub {
                $js->js_publish("demo.event", "event-" . ++$sent, sub {
                    my ($ack, $err) = @_;
                    if ($err) {
                        warn "publish error: $err\n";
                    } else {
                        print "published: stream=$ack->{stream} seq=$ack->{seq}\n";
                    }
                    if ($sent < 5) {
                        $send_next->();
                    } else {
                        # Check stream info
                        $js->stream_info('DEMO', sub {
                            my ($info, $err) = @_;
                            if ($info) {
                                print "stream state: msgs=$info->{state}{messages}\n";
                            }
                            $nats->disconnect;
                            EV::break;
                        });
                    }
                });
            };
            $send_next->();
        });
    },
);

EV::run;
