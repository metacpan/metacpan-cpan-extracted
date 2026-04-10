#!/usr/bin/env perl
# Live config watcher — watches KV bucket for config changes, applies them
# Requires: nats-server -js
use strict;
use warnings;
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::KV;

my $nats;
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "nats: @_\n" },
    on_connect => sub {
        my $js = EV::Nats::JetStream->new(nats => $nats);
        my $kv = EV::Nats::KV->new(js => $js, bucket => 'appconfig');

        $kv->create_bucket({ max_history => 10 }, sub {
            my ($info, $err) = @_;
            warn "bucket: $err\n" if $err && $err !~ /already/;

            # Set some initial config
            $kv->put('db.host', 'localhost', sub {});
            $kv->put('db.port', '5432', sub {});
            $kv->put('cache.ttl', '300', sub {});

            # Watch for changes
            my %config;
            $kv->watch('>', sub {
                my ($key, $value, $op) = @_;
                if ($op eq 'DEL' || $op eq 'PURGE') {
                    delete $config{$key};
                    print "config DELETED: $key\n";
                } else {
                    $config{$key} = $value;
                    print "config SET: $key = $value\n";
                }
                # Apply config (in a real app, trigger reconfiguration here)
                print "  current config: " . join(', ', map { "$_=$config{$_}" } sort keys %config) . "\n";
            });

            # Simulate config updates
            my $step = 0;
            my $t; $t = EV::timer 2, 2, sub {
                $step++;
                if ($step == 1) {
                    print "\n--- updating cache.ttl ---\n";
                    $kv->put('cache.ttl', '600', sub {});
                } elsif ($step == 2) {
                    print "\n--- adding new key ---\n";
                    $kv->put('feature.beta', 'enabled', sub {});
                } elsif ($step == 3) {
                    print "\n--- deleting key ---\n";
                    $kv->delete('feature.beta');
                } else {
                    undef $t;
                    $nats->drain(sub { EV::break });
                }
            };
        });
    },
);

EV::run;
