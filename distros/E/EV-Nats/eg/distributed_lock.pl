#!/usr/bin/env perl
# Distributed lock using KV create-if-not-exists semantics
# Requires: nats-server -js
use strict;
use warnings;
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::KV;

my $worker_id = shift || "w$$";

my $nats;
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "nats: @_\n" },
    on_connect => sub {
        my $js = EV::Nats::JetStream->new(nats => $nats);
        my $kv = EV::Nats::KV->new(js => $js, bucket => 'locks');

        $kv->create_bucket({ max_history => 1 }, sub {
            my ($info, $err) = @_;
            warn "bucket: $err\n" if $err && $err !~ /already/;

            my $lock_key = 'myresource';
            my $acquired = 0;

            # Try to acquire lock
            my $try_lock; $try_lock = sub {
                print "[$worker_id] trying to acquire lock '$lock_key'...\n";

                # create = put-if-not-exists
                $kv->create($lock_key, "$worker_id:" . time, sub {
                    my ($rev, $err) = @_;
                    if ($err) {
                        print "[$worker_id] lock held by another worker ($err), retrying in 2s\n";
                        my $retry; $retry = EV::timer 2, 0, sub {
                            undef $retry;
                            $try_lock->();
                        };
                        return;
                    }

                    $acquired = 1;
                    print "[$worker_id] LOCK ACQUIRED (rev=$rev)\n";
                    print "[$worker_id] doing critical work...\n";

                    # Hold lock for 3 seconds, then release
                    my $release; $release = EV::timer 3, 0, sub {
                        undef $release;
                        $kv->delete($lock_key, sub {
                            print "[$worker_id] LOCK RELEASED\n";
                            $nats->disconnect;
                            EV::break;
                        });
                    };
                });
            };

            $try_lock->();
        });
    },
);

my $guard = EV::timer 15, 0, sub {
    print "[$worker_id] timeout\n";
    $nats->disconnect;
    EV::break;
};

EV::run;
