#!/usr/bin/env perl
# Event sourcing — JetStream as append-only event log with replay
# Requires: nats-server -js
use strict;
use warnings;
use EV;
use EV::Nats;
use EV::Nats::JetStream;

my $mode = shift || 'both'; # 'produce', 'replay', or 'both'

my $nats;
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "nats: @_\n" },
    on_connect => sub {
        my $js = EV::Nats::JetStream->new(nats => $nats);

        # Create event stream
        $js->stream_create({
            name     => 'EVENTS',
            subjects => ['events.>'],
            retention => 'limits',
            max_age   => 3600_000_000_000, # 1 hour in nanoseconds
        }, sub {
            my ($info, $err) = @_;
            warn "stream: $err\n" if $err && $err !~ /already/;

            if ($mode eq 'produce' || $mode eq 'both') {
                # Publish domain events
                require JSON::PP;
                my @events = (
                    { type => 'user.created', data => { id => 1, name => 'Alice' } },
                    { type => 'user.created', data => { id => 2, name => 'Bob' } },
                    { type => 'order.placed', data => { id => 101, user_id => 1, amount => 42.50 } },
                    { type => 'user.updated', data => { id => 1, name => 'Alice Smith' } },
                    { type => 'order.placed', data => { id => 102, user_id => 2, amount => 18.00 } },
                    { type => 'order.shipped', data => { id => 101, tracking => 'TRK123' } },
                );

                my $published = 0;
                for my $event (@events) {
                    my $subject = "events.$event->{type}";
                    my $payload = JSON::PP::encode_json({
                        %$event,
                        timestamp => time,
                    });
                    $js->js_publish($subject, $payload, sub {
                        my ($ack, $err) = @_;
                        $published++;
                        printf "published: seq=%d %s\n", $ack->{seq} // 0, $event->{type}
                            unless $err;
                        if ($published >= scalar @events && $mode eq 'produce') {
                            $nats->disconnect;
                            EV::break;
                        }
                    });
                }
            }

            if ($mode eq 'replay' || $mode eq 'both') {
                my $delay = $mode eq 'both' ? 1 : 0;
                my $t; $t = EV::timer $delay, 0, sub {
                    undef $t;

                    # Replay: rebuild aggregate state from event log
                    print "\n--- replaying event log ---\n";
                    my %users;
                    my %orders;

                    # Subscribe to events.> to get all events
                    # In production, use a JetStream consumer for reliable replay
                    $nats->subscribe('events.>', sub {
                        my ($subject, $payload) = @_;
                        require JSON::PP;
                        my $event = eval { JSON::PP::decode_json($payload) };
                        return unless $event;

                        my $type = $event->{type};
                        if ($type eq 'user.created') {
                            $users{$event->{data}{id}} = $event->{data};
                            print "  +user: $event->{data}{name}\n";
                        } elsif ($type eq 'user.updated') {
                            $users{$event->{data}{id}} = { %{$users{$event->{data}{id}} || {}}, %{$event->{data}} };
                            print "  ~user: $event->{data}{name}\n";
                        } elsif ($type eq 'order.placed') {
                            $orders{$event->{data}{id}} = $event->{data};
                            print "  +order: #$event->{data}{id} \$$event->{data}{amount}\n";
                        } elsif ($type eq 'order.shipped') {
                            $orders{$event->{data}{id}}{tracking} = $event->{data}{tracking};
                            print "  ~order: #$event->{data}{id} shipped\n";
                        }
                    });

                    # After collecting events, print aggregate state
                    my $done; $done = EV::timer 3, 0, sub {
                        undef $done;
                        print "\n--- aggregate state ---\n";
                        print "users:\n";
                        for my $uid (sort keys %users) {
                            printf "  %d: %s\n", $uid, $users{$uid}{name};
                        }
                        print "orders:\n";
                        for my $oid (sort keys %orders) {
                            my $o = $orders{$oid};
                            printf "  %d: \$%.2f user=%d %s\n",
                                $oid, $o->{amount}, $o->{user_id},
                                $o->{tracking} ? "(shipped: $o->{tracking})" : "(pending)";
                        }
                        $nats->disconnect;
                        EV::break;
                    };
                };
            }
        });
    },
);

EV::run;
