#!/usr/bin/env perl
# Key-Value store example (requires NATS with JetStream: nats-server -js)
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
        my $kv = EV::Nats::KV->new(js => $js, bucket => 'myconfig');

        $kv->create_bucket({ max_history => 5 }, sub {
            my ($info, $err) = @_;
            warn "bucket: $err\n" if $err;

            $kv->put('app.name', 'MyApp', sub {
                my ($rev, $err) = @_;
                print "put app.name: rev=$rev\n" unless $err;

                $kv->put('app.version', '1.0', sub {
                    $kv->get('app.name', sub {
                        my ($val, $err) = @_;
                        print "get app.name: $val\n" unless $err;

                        $kv->keys(sub {
                            my ($keys, $err) = @_;
                            print "keys: @$keys\n" unless $err;

                            $kv->status(sub {
                                my ($st, $err) = @_;
                                print "bucket: $st->{values} values, $st->{bytes} bytes\n" unless $err;
                                $nats->disconnect;
                                EV::break;
                            });
                        });
                    });
                });
            });
        });
    },
);

EV::run;
