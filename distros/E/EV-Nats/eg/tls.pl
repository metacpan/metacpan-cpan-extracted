#!/usr/bin/env perl
# TLS connection example
# Requires: nats-server with TLS configured
use strict;
use warnings;
use EV;
use EV::Nats;

my $nats;
$nats = EV::Nats->new(
    host            => $ENV{NATS_HOST} // '127.0.0.1',
    port            => $ENV{NATS_PORT} // 4222,
    tls             => 1,
    tls_ca_file     => $ENV{NATS_CA_FILE},      # optional, uses system CAs if omitted
    tls_skip_verify => $ENV{NATS_SKIP_VERIFY},   # for self-signed certs
    on_error   => sub { warn "error: @_\n" },
    on_connect => sub {
        print "connected with TLS\n";
        $nats->publish('tls.test', 'encrypted hello');
        $nats->flush(sub {
            print "message flushed\n";
            $nats->disconnect;
            EV::break;
        });
    },
);

EV::run;
