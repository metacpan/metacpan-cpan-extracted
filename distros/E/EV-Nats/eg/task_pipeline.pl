#!/usr/bin/env perl
# Task pipeline — chained processing stages via queue groups
# Stage 1 (validate) -> Stage 2 (enrich) -> Stage 3 (store)
# Each stage is a queue group so work is load-balanced
use strict;
use warnings;
use EV;
use EV::Nats;

my $role = shift || 'all'; # 'producer', 'stage1', 'stage2', 'stage3', or 'all'
my $nats;

$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "nats: @_\n" },
    on_connect => sub {
        if ($role eq 'stage1' || $role eq 'all') {
            # Stage 1: validate input
            $nats->subscribe('pipeline.stage1', sub {
                my ($subj, $payload) = @_;
                if ($payload =~ /^\d+$/) {
                    $nats->publish('pipeline.stage2', "validated:$payload");
                } else {
                    print "stage1: rejected '$payload'\n";
                }
            }, 'validators');
        }

        if ($role eq 'stage2' || $role eq 'all') {
            # Stage 2: enrich data
            $nats->subscribe('pipeline.stage2', sub {
                my ($subj, $payload) = @_;
                my ($status, $data) = split /:/, $payload, 2;
                my $enriched = "$data:" . time . ":" . int(rand(1000));
                $nats->publish('pipeline.stage3', "enriched:$enriched");
            }, 'enrichers');
        }

        if ($role eq 'stage3' || $role eq 'all') {
            # Stage 3: store result
            my $stored = 0;
            $nats->subscribe('pipeline.stage3', sub {
                my ($subj, $payload) = @_;
                $stored++;
                print "stage3: stored [$stored] $payload\n";
            }, 'storers');
        }

        if ($role eq 'producer' || $role eq 'all') {
            my $n = 0;
            my $t; $t = EV::timer 0.2, 0, sub {
                undef $t;
                # Submit tasks
                my @items = (42, 'bad', 7, 99, 'invalid', 13, 0, 256);
                for my $item (@items) {
                    $nats->publish('pipeline.stage1', "$item");
                }
                print "producer: submitted " . scalar(@items) . " tasks\n";

                # Wait for pipeline to process
                my $done; $done = EV::timer 2, 0, sub {
                    undef $done;
                    my %s = $nats->stats;
                    print "done: $s{msgs_out} sent, $s{msgs_in} received\n";
                    $nats->disconnect;
                    EV::break;
                };
            };
        }
    },
);

EV::run;
