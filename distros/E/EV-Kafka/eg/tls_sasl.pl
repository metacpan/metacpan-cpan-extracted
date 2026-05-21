#!/usr/bin/env perl
# TLS + SASL/SCRAM-SHA-256 example.
#
# Set KAFKA_BROKER to a TLS listener (e.g. host:9093). Provide the CA cert
# in KAFKA_TLS_CA, and credentials via KAFKA_USER and KAFKA_PASS. The
# client warns at construction if SASL is configured without TLS.
#
# Quick local test with Redpanda:
#   docker run -e RP_BOOTSTRAP_USER=admin:secret123 \
#     redpandadata/redpanda:latest start --kafka-addr=...

use strict;
use warnings;
use EV;
use EV::Kafka;

my $kafka = EV::Kafka->new(
    brokers          => $ENV{KAFKA_BROKER}  // '127.0.0.1:9093',
    tls              => 1,
    tls_ca_file      => $ENV{KAFKA_TLS_CA},      # may be undef for system CA
    tls_skip_verify  => $ENV{KAFKA_TLS_INSECURE} ? 1 : 0,
    sasl             => {
        mechanism => $ENV{KAFKA_SASL_MECH} // 'SCRAM-SHA-256',
        username  => $ENV{KAFKA_USER}      // 'admin',
        password  => $ENV{KAFKA_PASS}      // 'secret123',
    },
    on_error => sub { warn "kafka: @_\n"; EV::break },
);

$kafka->connect(sub {
    my $meta = shift;
    printf "connected; cluster has %d broker(s)\n",
        scalar @{$meta->{brokers}};

    $kafka->produce('tls-test', 'k', 'authenticated payload', sub {
        my ($r, $err) = @_;
        die "produce: $err" if $err;
        print "produced over TLS+SASL at offset ",
            $r->{topics}[0]{partitions}[0]{base_offset}, "\n";
        $kafka->close(sub { EV::break });
    });
});

EV::run;
